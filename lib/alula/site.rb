require 'yaml'
require 'jekyll'
require 'sprockets'
require 'RMagick'
require 'active_support/inflector/methods'
require 'progressbar'

require 'alula/theme'
require 'alula/plugin'

# Compressors
require 'alula/compressors'

# Jekyll extensions, plugins, tags
# These are used always in every blog, i.e. mandatory plugins
require 'alula/plugins/assets'

module Alula
  class Site
    
    attr_reader :config, :jekyll
    
    def initialize(override = {})
      # Load configuration
      @config = YAML.load_file('config.yml').deep_merge(override)
      
      # Register local theme path
      Alula::Theme.register("themes")
      
      # Initialize Jekyll
      options         = Jekyll::DEFAULTS.deep_merge({
        'source'      => '_tmp',
        'destination' => 'public',
        'markdown'    => 'kramdown',
        
        # Site options
        'title'          => @config["title"],
        'tagline'        => @config["tagline"],
        'author'         => @config["author"],
        'root'           => @config["root"],
        'asset_path'     => "#{@config["root"]}assets",
        'permalinks'     => @config["permalinks"],
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
      @sprockets.append_path File.join("attachments")
      
      # Vendor assets
      vendor_path = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. .. vendor}))
      @sprockets.append_path File.join(vendor_path, "stylesheets")
      @sprockets.append_path File.join(vendor_path, "javascripts")
      
      # Initialize blog plugins
      @config["plugins"].each do |plugin, opts|
        require "alula/plugins/#{plugin}"
        
        plugin_class = Alula::Plugins.const_get(ActiveSupport::Inflector.camelize(plugin, true))
        path = plugin_class.install(opts)
        @sprockets.append_path File.join(path, "stylesheets")
        @sprockets.append_path File.join(path, "javascripts")
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
    
    private
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
      
      FileUtils.mkdir_p File.join("_tmp", "assets")
    end
    
    def assetgen
      puts "==> Generating assets"
      
      width, height = @config["thumbnails"].split("x").collect {|i| i.to_i }
      
      # Get all attachements
      originals_path = File.join("attachments", "_originals")
      thumbnails_path = File.join("attachments", "_thumbnails")
      
      assets = Dir[File.join(originals_path, "**", "*")]
        .select {|f| File.file?(f) }
        .collect {|f| File.join(f.split("/")[2..-1])}
      pb = ProgressBar.new "Assets", assets.count
      
      assets.each do |original|
        unless File.exists?(File.join(thumbnails_path, original))
          image = Magick::Image.read(File.join(originals_path, original)).first
          image.crop_resized!(width, height, Magick::NorthGravity)
          FileUtils.mkdir_p File.dirname(File.join(thumbnails_path, original))
          image.write(File.join(thumbnails_path, original))
        end
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
        @config["plugins"].each { |plugin, opts| tf.puts " *=require #{plugin}" }
        tf.puts " */"
      end
      
      # Package javascript
      File.open(File.join("_tmp", "assets", "scripts.js"), "w") do |tf|
        tf.puts "//=require #{@config["theme"]}"
        # Plugins
        @config["plugins"].each { |plugin, opts| tf.puts "//=require #{plugin}" }
      end

      File.open(File.join("_tmp", "assets", "scripts_body.js"), "w") do |tf|
        tf.puts "//=require #{@config["theme"]}_body"
        # Plugins
        @config["plugins"].each { |plugin, opts| tf.puts "//=require #{plugin}_body" }
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
end
