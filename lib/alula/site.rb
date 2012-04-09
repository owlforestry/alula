require 'yaml'
require 'jekyll'
require 'sprockets'
require 'active_support/inflector/methods'
require 'progressbar'
require 'stringex'

require 'alula/config'
require 'alula/theme'
require 'alula/plugins'
require 'alula/assetmanager'

# Compressors
require 'alula/compressors'

# Jekyll extensions, plugins, tags
# These are used always in every blog, i.e. mandatory plugins
require 'alula/plugins/assets'
require 'alula/plugins/pagination'

module Alula
  class Site
    
    attr_reader :config, :jekyll
    
    def initialize(override = {})
      # Load configuration
      Alula::Config.init(override)
      @config = Alula::Config.fetch
      
      # Register local theme path
      Alula::Theme.register("themes")
      
      # Initialize Jekyll
      options         = Alula::DEFAULTS.deep_merge({
        # Site options
        'title'          => @config["title"],
        'tagline'        => @config["tagline"],
        'author'         => @config["author"],
        'root'           => @config["root"],
        'asset_path'     => File.join(@config["root"], "assets"),
        'permalink'      => @config["permalink"],
        'paginate'       => @config["paginate"],
        'pagination_dir' => @config["pagination_dir"],
        'excerpt_link'   => @config["excerpt_link"],
      })
      
      @jekyll = Jekyll::Site.new(options)
      
      @themepath = Alula::Theme.find_theme(@config['theme'])
      unless @themepath
        raise "Cannot find theme #{@config['theme']}"
      end
      
      # Initialize Sprockets
      @sprockets = Sprockets::Environment.new
      
      # Append our helpers
      @sprockets.context_class.class_eval do
        def asset_url(asset)
          unless manifest.assets[asset]
            manifest.compile(asset)
          end
          File.join(jekyll.config["asset_path"], manifest.assets[asset])
        end
        
        def manifest; @@manifest; end
        def self.manifest=(manifest); @@manifest = manifest; end

        def jekyll; @@jekyll; end
        def self.jekyll=(manifest); @@jekyll = manifest; end

      end
      
      # Set our compressor
      if @config['asset_compress']
        @sprockets.css_compressor = Alula::Compressors::CSSCompressor.new
        @sprockets.js_compressor = Alula::Compressors::JSCompressor.new
        
        [Jekyll::Post, Jekyll::Page].each do |klass|
          klass.send(:include, Alula::Compressors::HTMLCompressor)
          klass.send(:alias_method, :output_without_compression, :output)
          klass.send(:alias_method, :output, :output_with_compression)
        end
      end

      # Add theme to asset paths
      @sprockets.append_path File.join(@themepath, @config['theme'], "stylesheets")
      @sprockets.append_path File.join(@themepath, @config['theme'], "javascripts")
      @sprockets.append_path File.join(@themepath, @config['theme'], "assets")

      # Generated assets
      @sprockets.append_path File.join("_tmp", "assets")
      
      # Attachments
      @sprockets.append_path File.join("attachments", "_generated")
      
      # Vendor assets
      vendor_path = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. .. vendor}))
      @sprockets.append_path File.join(vendor_path, "stylesheets")
      @sprockets.append_path File.join(vendor_path, "javascripts")
      
      # Initialize blog plugins
      if @config["plugins"] != nil
        @config["plugins"].each do |plugin, opts|
          require "alula/plugins/#{plugin}"
        
          plugin_class = Alula::Plugins.const_get(ActiveSupport::Inflector.camelize(plugin, true))
          path = plugin_class.install(opts)
          @sprockets.append_path File.join(path, "stylesheets")
          @sprockets.append_path File.join(path, "javascripts")
          @sprockets.append_path File.join(path, "assets")
        end
      end
    end
    
    def generate
      puts "==> Generating blog"
      
      # Prepare Jekyll environment
      prepare
      
      # Generate missing assets
      assetgen
      
      # Generate asset manifest
      compile
      
      # Execute jekyll
      process
      
      # Cleanup
      cleanup
    end
    
    def preview
      generate
      
      require 'webrick'
        # include WEBrick

        FileUtils.mkdir_p("public")

        mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
        mime_types.store 'js', 'application/javascript'

        s = WEBrick::HTTPServer.new(
          :Port            => 3000,
          :MimeTypes       => mime_types
        )
        s.mount('/', WEBrick::HTTPServlet::FileHandler, "public")
        t = Thread.new {
          s.start
        }

        trap("INT") { s.shutdown }
        t.join()
    end
    
    def asset_attach(a_post, assets)
      # Find the post
      post = find_post(a_post) or raise "Cannot find post #{a_post}"
      
      /(?<date>(\d{4}-\d{2}-\d{2}))/ =~ post
      date = Time.parse(date)
      asset_path = File.join(%w{%Y %m %d}.collect{|f| date.strftime(f) })
      
      helper = Alula::AssetManager.new(asset_path, @config)
      
      post_io = File.open(post, "a")
      assets.each do |asset|
        type, asset_name = helper.process(asset)
        if asset_name
          # Asset processed
          puts "(#{asset_name}) done."
          if handler = Alula::Plugins.attachment_handler(type)
            post_io.puts handler.call(asset_name)
          else
            case type
            when :image
              post_io.puts "{% image _images/#{asset_name} %}"
            when :movie
              post_io.puts "{% video #{asset_name} %}"
            else
              post_io.puts "{% comment %}Unknown asset type #{type}{% endcomment %}"
            end
          end
        else
          puts "(#{asset}) cannot process."
        end
      end
    end
    
    def clean
      cleanup
      FileUtils.rm_rf(Dir[File.join("attachments", "_images", "*")])
      FileUtils.rm_rf(Dir[File.join("attachments", "_thumbnails", "*")])
    end
    
    private
    def find_post(post)
      if File.exists?(post)
        return post
      elsif File.exists?(File.join("posts", post))
        return File.join("posts", post)
      else
        # Try to find by title
        title = post.to_url
        posts = Dir[File.join("posts", "*")].select { |p| p =~ /#{title}/ }
        if posts.count == 1
          return posts.first
        end
      end
    end
    
    def prepare
      puts "==> Prepare"
      # Clean our temporary folder
      FileUtils.rm_rf "_tmp"
      FileUtils.mkdir "_tmp"
      FileUtils.rm_rf "public"
      FileUtils.mkdir "public"
      
      # Copy Jekyll files
      # Install our theme
      FileUtils.mkdir_p File.join("_tmp", "_layouts")
      FileUtils.mkdir_p File.join("_tmp", "_includes")

      FileUtils.cp_r Dir[File.join(@themepath, @config['theme'], "layouts", "*")], File.join("_tmp", "_layouts")
      FileUtils.cp_r Dir[File.join(@themepath, @config['theme'], "includes", "*")], File.join("_tmp", "_includes")

      FileUtils.cp_r Dir[File.join(@themepath, @config['theme'], "site", "*")], "_tmp"
      
      # Copy posts
      FileUtils.mkdir_p File.join("_tmp", "_posts")
      FileUtils.cp_r Dir[File.join("posts", "*")], File.join("_tmp", "_posts")
      
      # Copy pages
      Dir[File.join("pages", "**", "*")].each do |page|
        next unless File.file?(page)
        page = File.join(page.split("/")[1..-1])
        
        FileUtils.mkdir_p File.join("_tmp", File.dirname(page))
        FileUtils.cp File.join("pages", page), File.join("_tmp", page)
      end
      
      FileUtils.mkdir_p File.join("_tmp", "assets")
    end
    
    def assetgen
      puts "==> Generating assets"
      
      # width, height = @config["images"]["thumbnails"].split("x").collect {|i| i.to_i }
      
      # Get all attachements
      attachments_path = File.join("attachments", "originals")
      images_path = File.join("attachments", "_generated", "images")
      thumbnails_path = File.join("attachments", "_generated", "thumbnails")
      
      attachments = Dir[File.join(attachments_path, "**", "*")]
        .select {|f| File.file?(f) }
        .collect {|f| File.join(f.split("/")[2..-1])}
      pb = ProgressBar.new "Assets", attachments.count
      
      attachments.each do |asset|
        helper = Alula::AssetManager.new(File.dirname(asset), @config)
        type, asset_name = helper.process(File.join(attachments_path, asset))
        
        pb.inc
      end

      pb.finish
    end
    
    def compile
      puts "==> Compiling assets"
      
      # Package stylesheet
      File.open(File.join("_tmp", "assets", "styles.css"), "w") do |tf|
        tf.puts "/*"
        tf.puts " *=require #{@config["theme"]}"
        # Plugins
        if @config["plugins"]
          @config["plugins"].each { |plugin, opts| tf.puts " *=require #{plugin}" }
        end
        tf.puts " */"
      end
      
      # Package javascript
      File.open(File.join("_tmp", "assets", "scripts.js"), "w") do |tf|
        tf.puts "//=require #{@config["theme"]}"
        # Plugins
        if @config["plugins"]
          @config["plugins"].each { |plugin, opts| tf.puts "//=require #{plugin}" }
        end
      end

      File.open(File.join("_tmp", "assets", "scripts_body.js"), "w") do |tf|
        tf.puts "//=require #{@config["theme"]}_body"
        # Plugins
        if @config["plugins"]
          @config["plugins"].each { |plugin, opts| tf.puts "//=require #{plugin}_body" }
        end
      end
      
      
      @manifest = Sprockets::Manifest.new(@sprockets, File.join("public", "assets"))
      @sprockets.context_class.manifest = @manifest
      @sprockets.context_class.jekyll = @jekyll
      
      # Moneky-patch manifest to keep track of used assets
      Sprockets::Manifest.send(:include, Alula::ManifestAddons)
      Sprockets::Manifest.send(:alias_method, :assets_without_tracking, :assets)
      Sprockets::Manifest.send(:alias_method, :assets, :assets_with_tracking)
      

      # Compile assets
      @manifest.compile
      
      # Inject our manifest to jekyll
      @jekyll.config["manifest"] = @manifest
      
      # Cleanup
      %w{styles.css scripts.js scripts_body.js}.each do |f|
        FileUtils.rm(File.join("_tmp", "assets", f))
      end
    end
    
    def process
      puts "==> Processing Jekyll site"
      
      @jekyll.reset
      @jekyll.read
      @jekyll.generate
      @jekyll.render
      @jekyll.write
    end
    
    def cleanup
      puts "==> Cleaning up"
      
      FileUtils.rm_rf "_tmp"
      
      unused_assets = @manifest.files.keys - @manifest.assets.used
      unused_assets.each do |asset|
        FileUtils.rm File.join("public", "assets", asset)
      end
    end
  end
  
  DEFAULTS = Jekyll::DEFAULTS.deep_merge({
    'source'      => '_tmp',
    'destination' => 'public',
    'markdown'    => 'kramdown',
  })
  
  module ManifestAddons
    def assets_with_tracking
      @data['_assets'] ||= AssetTracker.new assets_without_tracking
    end
    
    def used_assets
      @data['_assets'].used
    end
    
    class AssetTracker
      def initialize(hash)
        @hash = hash
        @used = []
      end
      
      def used
        @used.uniq
      end
      
      def [](key)
        @used << @hash[key]
        @hash[key]
      end
      
      def []=(key, value)
        @hash[key] = value
      end
    end
  end
end