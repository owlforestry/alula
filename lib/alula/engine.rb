require 'active_support/inflector/methods'
require 'sprockets'
require 'tilt'
require 'json'

require 'alula/engine/config'
require 'alula/engine/manifest'
require 'alula/engine/content'
require 'alula/engine/helpers'
require 'alula/engine/plugins'
require 'alula/engine/filter'
require 'alula/engine/compressors'
require 'alula/engine/attachmentprocessor'
require 'alula/engine/progressbar'

module Alula
  class Engine
    attr_reader :config, :posts, :pages, :statics, :attachment_mapping, :filters
    
    def initialize(override = {})
      # Load our configuration
      @config = Config.shared(override)
      
      # Initalize user content
      @layouts = {}
      @posts = []
      @pages = []
      @statics = []
      
      @attachment_mapping = {}
      @filters = []
      
      # Load site plugins
      load_plugins
      
      # Initialize assets environment
      init_environment
    end

    # General methods to call
    # Used usually from CLI/Site level
    
    # Generate
    # Generates whole site from scratch
    def generate
      # Prepare environment
      prepare
      
      # Read all our content (posts)
      read_content
      
      # Process attachements
      process_attachments
      
      # Compile assets
      compile_assets
      
      # Actual site rendering
      render_site
    end
    
    # Prepares alula environment
    def prepare(clean = true)
      puts "==> Preparing environment" + (!clean ? " (preserving existing)" : "") 
      
      # Cleaning up, just get rid of the whole public folder
      if clean
        FileUtils.rm_rf config.public_path
      end
      
      # Creating directory tree
      FileUtils.mkdir_p File.join("attachments", "_generated")
      FileUtils.mkdir_p config.public_path
      FileUtils.mkdir_p File.join(config.public_path, config.assets_path)
    end
    
    def process_attachments
      puts "==> Processing attachments"
      
      # Get all attachements
      attachments_path = File.join(config.attachments_path, "originals")
      images_path = File.join(config.attachments_path, "_generated", "images")
      thumbnails_path = File.join(config.attachments_path, "_generated", "thumbnails")
      
      attachments = Dir[File.join(attachments_path, "**", "*")]
        .select {|f| File.file?(f) }
        .collect {|f| File.join(f.split("/")[2..-1])}
      pbar = ProgressBar.new "Attachments", attachments.count
      
      processor = AttachmentProcessor.new(self)
      
      attachments.each do |attachment|
        # helper = Alula::AssetManager.new(File.dirname(asset), config)
        # type, asset_name = helper.process(File.join(attachments_path, asset), :keepcase => true)
        # Keep original filename case
        
        # Detect our proper asset directory from filename (as it is already in originals)
        asset_path = File.dirname(attachment)
        
        # Process attachment
        type, asset_name = processor.process(attachment, :asset_path => asset_path, :path => attachments_path)
        
        pbar.inc
      end
      pbar.finish
      
      # Save attachment mapping
      File.open(File.join(config.attachments_path, "mapping.json"), "w") do |io|
        io.puts attachment_mapping.to_json
      end
    end
    
    def compile_assets
      puts "==> Compiling assets"
      
      theme_assets = File.join(Alula::Engine::Theme.find(config.theme), "assets")
      # Package stylesheets
      File.open(File.join(config.public_path, config.assets_path, "styles.css"), "w") do |io|
        io.puts "/*"
        io.puts " *=require #{config.theme}" if Dir[File.join(theme_assets, "stylesheets", "#{config.theme}.css*")].count == 1
        # Plugins
        config.plugins.each do |plugin, opts|
          io.puts " *=require #{plugin}" if Dir[File.join(opts[:path], "assets", "stylesheets", "#{plugin}.css*")].count == 1
        end
        io.puts "*/"
      end
      
      # Package javascripts
      File.open(File.join(config.public_path, config.assets_path, "scripts.js"), "w") do |io|
        io.puts "//=require #{config.theme}" if Dir[File.join(theme_assets, "javascripts", "#{config.theme}.js*")].count == 1
        io.puts "//=require lazyload" if config.images["lazyload"]
        io.puts "//=require emphasis" if config.emphasis
        # Plugins
        config.plugins.each do |plugin, opts|
          io.puts "//=require #{plugin}" if Dir[File.join(opts[:path], "assets", "javascripts", "#{plugin}.js*")].count == 1
        end
      end
      
      @manifest = Manifest.new(@sprockets, File.join("public", "assets"))
      @manifest.tracker = ProgressBar.new "Compiling assets", @sprockets.each_logical_path.count
      @manifest.compile
      @manifest.tracker.finish
      
    end
    
    def render_site
      puts "==> Generating site"
      
      # Preload all our theme layouts
      load_layouts(config.theme)
      
      context = Context.new({
        "config"      => config,
        "site"        => config,
        "engine"      => self,
        "environment" => @sprockets,
        "attachments" => @attachment_mapping
      })
      context.send(:extend, Helpers)
      
      total = pages.count + posts.count + statics.count
      pbar = ProgressBar.new "Rendering", total
      
      # Render posts
      # (posts + pages).each do |page|
      (posts + pages).each do |page|
        # Output with layout
        # layout = find_layout(page.data["layout"])
        
        # Start ensure-block to keep context variables nice and clean
        begin
          if page.posts
            page.posts.select {|post| post.parent = page; true }
          end
          
          context.page = page
          
          # Render and write document in one pass
          page.write(context)
        ensure
          context.page = nil
        end
        
        # HTML Compressor
        # page.write
        
        pbar.inc
      end
      # Copy static content
      statics.each do |static, path|
        FileUtils.cp path, File.join(config.public_path, static)
        pbar.inc
      end

      pbar.finish
    end
    
    def find_view(view)
      @layouts["_#{view}"] or raise "Cannot find view #{view} for theme #{config.theme}"
    end
    
    def find_layout(layout)
      @layouts[layout] or raise "Cannot find layout #{layout} for theme #{config.theme}"
    end
    
    private
    def init_environment
      @sprockets = Sprockets::Environment.new
      
      @sprockets.context_class.class_eval do
        include Helpers
        
        def config; Alula::Engine::Config.shared; end
      end
      
      # Add compressor support
      if config["production"]
        @sprockets.css_compressor = Alula::Engine::Compressors::CSSCompressor.new
        @sprockets.js_compressor = Alula::Engine::Compressors::JSCompressor.new
      end
      
      # Add self-generated assets
      @sprockets.append_path File.join(config.public_path, config.assets_path)
      
      # Add theme assets
      theme_dir = Alula::Engine::Theme.find(config.theme)
      %w{stylesheets javascripts images}.each do |asset_dir|
        asset_path = File.join(theme_dir, "assets", asset_dir)
        @sprockets.append_path asset_path
      end
      
      # Add plugins assets
      config.plugins.each do |plugin, opts|
        plugin_dir = opts[:path]
        %w{stylesheets javascripts images}.each do |asset_dir|
          asset_path = File.join(plugin_dir, "assets", asset_dir)
          @sprockets.append_path asset_path
        end
      end
      
      # Add attachements
      @sprockets.append_path File.join("attachments", "_generated")

      # Add site assets
      @sprockets.append_path config.static_path
      
      # Vendored assets (jQuery etc)
      vendor_path = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. .. vendor}))
      %w{stylesheets javascripts images}.inject(nil) { |c, p| @sprockets.append_path File.join(vendor_path, p) }
    end
    
    def load_plugins
      if config.plugins
        config.plugins.each do |plugin, opts|
          require "alula/engine/plugins/#{plugin}"
        
          klass = Alula::Engine::Plugins.const_get(ActiveSupport::Inflector.camelize(plugin, true))
          path = klass.install(opts)
          config.plugins[plugin] = {:path => path, :options => opts, :class => klass }
        end
      end
      
      # Load filters
      if config.filters
        config.filters.each do |filter, opts|
          require "alula/engine/filters/#{filter}"
        
          klass = Alula::Engine::Filter.const_get(ActiveSupport::Inflector.camelize(filter, true))
          @filters << klass.new(opts)
        end
      end
    end
    
    def read_content
      # Posts
      Dir.chdir(config.posts_path) { Dir["*"] }.each do |post|
        next if File.directory?(File.join(config.posts_path, post))
        @posts << Post.new(self, config.posts_path, post)
      end
      @posts.sort!.reverse!
      
      # Theme content with site content
      theme_dir = Alula::Engine::Theme.find(config.theme)
      @blog_content = {}
      Dir.chdir(File.join(theme_dir, "content")) { Dir["**/*"] }.each do |content|
        next if File.directory?(File.join(theme_dir, "content", content))
        dir = File.dirname(content)
        base = File.basename(content, File.extname(content))
        content_name = (dir == "." ? base : File.join(dir, base))

        @blog_content[content_name] = [content, File.join(theme_dir, "content")]
      end
      Dir.chdir(config.content_path) { Dir["**/*"] }.each do |content|
        next if File.directory?(File.join(config.content_path, content))
        
        dir = File.dirname(content)
        base = File.basename(content, File.extname(content))
        content_name = (dir == "." ? base : File.join(dir, base))

        @blog_content[content_name] = [content, config.content_path]
      end

      @blog_content.each do |content_name, arr|
        content, path = *arr
        next if content_name == config.paginate_page
        
        # Do we have page?
        if File.read(File.join(path, content), 3) == "---"
          @pages << Page.new(self, path, content)
        else
          @statics << [content, File.join(path, content)]
        end
      end
      
      # Paginate index
      paginate("index")
    end
    
    def load_layouts(theme)
      theme_dir = Alula::Engine::Theme.find(theme)
      
      Dir[File.join(theme_dir, "layouts", "*")].each do |layout|
        /(?<basename>(?:.*?))(?<engines>(?:\..+))/ =~ File.basename(layout)
        options = case File.extname(layout)[1..-1]
        when "haml"
          { :format => :html5, :ugly => config["production"] }
        else
          {}
        end
        @layouts[basename] = Tilt.new layout, nil, options
      end
    end
    
    def paginate(page)
      content, path = *@blog_content[page]
      
      (0..num_pages).each do |page|
        name = if page == 0
          content
        else
          {
            "page"  => (page + 1).to_s,
          }.inject(config.paginate_path) { |result, token|
            result.gsub(/:#{Regexp.escape token.first}/, token.last)
          }.gsub(/\/\//, '/')
        end
        @pages << Page.new(self, path, content, {
          :page_num => (page + 1),  # Make prettier, starting pages from 1 instead of 0
          :total_pages => (num_pages + 1),
          :name => name,
          :posts => @posts.slice(config.paginate * page, config.paginate)
        })
      end
    end
    
    def num_pages
      (@posts.count / config.paginate).ceil
    end
  end
end
