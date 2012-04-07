require 'yaml'
require 'jekyll'
require 'sprockets'
require 'active_support/inflector/methods'
require 'progressbar'
require 'stringex'

require 'alula/theme'
require 'alula/plugins'
require 'alula/assethelper'

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
      @config = YAML.load_file('config.yml').deep_merge(override)
      
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
      
      helper = Alula::AssetHelper.new(asset_path, @config)
      
      post_io = File.open(post, "a")
      assets.each do |asset|
        type, generated = helper.process(asset, :type => :attachment)
        tn_type, tn_generated = helper.process(asset, :type => :thumbnail)
        if generated and tn_generated
          # Asset processed
          puts "(#{asset}) done."
          if handler = Alula::Plugins.attachment_handler(type)
            post_io.puts handler.call(generated[0])
          else
            post_io.puts "{% image _images/#{generated[0]} %}"
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
      
      width, height = @config["images"]["thumbnails"].split("x").collect {|i| i.to_i }
      
      # Get all attachements
      images_path = File.join("attachments", "_generated", "images")
      thumbnails_path = File.join("attachments", "_generated", "thumbnails")
      
      assets = Dir[File.join(images_path, "**", "*")]
        .select {|f| File.file?(f) }
        .collect {|f| File.join(f.split("/")[3..-1])}
      pb = ProgressBar.new "Assets", assets.count
      # helper = Alula::AssetHelper.new(asset_path, @config)
      
      assets.each do |asset|
        unless File.exists?(File.join(thumbnails_path, asset))
          helper = Alula::AssetHelper.new(File.dirname(asset), @config)
          tn_type, tn_generated = helper.process(File.join("attachments", "originals", asset), :type => :thumbnail)
          pb.inc
        end
      end
      # assets.each do |original|
      #   unless File.exists?(File.join(thumbnails_path, original))
      #     image = Magick::Image.read(File.join(originals_path, original)).first
      #     image.crop_resized!(width, height, Magick::NorthGravity)
      #     FileUtils.mkdir_p File.dirname(File.join(thumbnails_path, original))
      #     image.write(File.join(thumbnails_path, original))
      #   end
      #   pb.inc
      # end
      
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

      # Compile assets
      @manifest.compile
      # @manifest.compile([
      #   # Stylesheet
      #   "styles.css",
      #   
      #   # Javascript
      #   "javascripts.js",
      #   
      #   # Attachments
      #   Dir[File.join("attachments", "**", "*")]
      #     .select {|f| File.file?(f) }
      #     .collect {|f| File.join(f.split("/")[1..-1])},
      # ])
      
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
    end
  end
  
  DEFAULTS = Jekyll::DEFAULTS.deep_merge({
    'source'      => '_tmp',
    'destination' => 'public',
    'markdown'    => 'kramdown',
    
    'pagination_dir' => '/page/',
  })
end
