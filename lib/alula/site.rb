require 'alula/core_ext'

require 'alula/config'
require 'alula/plugin'
require 'alula/storage'
require 'alula/content'
require 'alula/context'
require 'alula/generator'
require 'alula/attachment_processor'
require 'alula/compressors'
require 'alula/cdn'
require 'alula/helpers'
require 'alula/progress'

require 'thor'
require 'sprockets'
require 'i18n'
require 'parallel'
require 'hashie/mash'

# Silence Tilt
require 'sass'
require 'coffee-script'

module Alula
  class Site
    def self.instance; @@instance; end
    
    # Global configuration
    attr_reader :config
    
    # Storage
    attr_reader :storage
    
    # Context for rendering
    attr_reader :context
    
    # Progress displayer
    attr_reader :progress
    
    # CDN Resolver for Site
    attr_reader :cdn
    
    # Site Plugins
    attr_reader :plugins
    
    # Site filters
    attr_reader :filters
    
    # Compressors
    attr_reader :compressors
    
    # Site metadata information
    attr_reader :metadata
    
    # Site attachment mapping
    attr_reader :attachments
    
    # Theme
    attr_reader :theme
    
    # User generated content
    attr_reader :content

    # System generated content, pages, pagination, etc.
    attr_reader :generated
    
    def initialize(options)
      @@instance = self
      
      # Read local config
      @config = Config.new(options)

      @storage = Storage.load(site: self)
      
      @metadata = Content::Metadata.new({
        base_locale: @config.locale,
        environment: @config.environment,
        
        title: @config.title,
        author: @config.author,
        tagline: @config.tagline,
        url: @config.url,
        
        theme: @config.theme,
        
        # Use this to store information of GIT site or note
        git: ::File.directory?(".git"),
      })
      
      # Progress displayer
      @progress = Progress.new(debug: options["debug"])
      
      # Compressors
      compressors = if @config.assets.compress
        {
          html: Alula::Compressors::HTMLCompressor.new,
          css: Alula::Compressors::CSSCompressor.new,
          js: Alula::Compressors::JSCompressor.new,
        }
      else
        {
          html: Alula::Compressors::DummyCompressor.new,
          css: Alula::Compressors::DummyCompressor.new,
          js: Alula::Compressors::DummyCompressor.new,
        }
      end
      @compressors = Hashie::Mash.new(compressors)
      
      @attachments = AttachmentProcessor.new(site: self)
      
      # Set up CDN resolver
      @cdn = CDN.load(site: self)
      
      @plugins = {}
      
      @filters = {}
      
      # Set up I18n
      l10n_path = File.join(File.dirname(__FILE__), "..", "..", "locales", "l10n", "*.yml")
      locale_path = File.join(File.dirname(__FILE__), "..", "..", "locales", "*.yml")
      custom_locale_path = File.join(@storage.path(:custom, "locales"), "*.yml")
      I18n.load_path += Dir[l10n_path]
      I18n.load_path += Dir[locale_path]
      I18n.load_path += Dir[custom_locale_path]
      I18n.default_locale = @config.locale
      
      # Set up default head addons
      Alula::Plugin.addon(:head, "<meta name=\"generator\" content=\"Alula #{Alula::VERSION}\">")
      Alula::Plugin.addon(:head, ->(context){"<link rel=\"icon\" type=\"image/png\" href=\"#{context.asset_url('favicon.png')}\">"})
    end
    
    # Compiles a site to static website
    def generate
      # Load our plugins and filters
      load_plugins
      load_filters
      
      # Prepare public folder
      prepare(true)
      
      load_content
      
      process_attachments
      
      compile_assets
      
      render
      
      cleanup
      # Store cached version of configuration
      cached_config = File.join(storage.path(:cache), "config.yml")
      @config.write_cache(cached_config)
    end
    
    # Proxy to metadata
    def method_missing(meth, *args, &blk)
      # Proxy to metadata
      if !meth[/=$/] and self.metadata.respond_to?(meth)
        args.unshift(self.context.locale || self.config.locale) if args.empty?
        self.metadata.send(meth, *args)
      else
        super
      end
    end
    
    private
    def load_plugins
      config.plugins.each do |name, options|
        if plugin = Alula::Plugin.load(name, options)
          @plugins[name] = plugin
        end
      end
    end
    
    def load_filters
      config.content.filters.each do |name, options|
        if filter = Alula::Filter.load(name, options)
          @filters[name] = filter
        end
      end
    end
    
    def prepare(preserve = false)
      say "==> Preparing environment" + (preserve ? " (preserving existing files)" : "")
      
      # Delegate preparations to storage module
      self.storage.prepare(preserve)
      
      # Load theme
      @context = Alula::Context.new(site: self, storage: self.storage)
      @context.send(:extend, Helpers)
      
      @theme = Alula::Theme.load(site: self)
      
      # Create our asset environment
      @environment = Environment.new
      # Add compressor support
      # if config.environment == "production"
      @environment.css_compressor = @compressors.css
      @environment.js_compressor = @compressors.js
      # end
      @environment.context_class.class_eval do
        # include Helpers
        def context; Alula::Site.instance.context; end
        def method_missing(meth, *args, &blk)
          return context.send(meth, *args, &blk) if context.respond_to?(meth)
          super
        end
      end
      @context.environment = @environment
      @context.attachments = self.attachments
      
      # Add generated attachements
      @environment.append_path @storage.path(:cache, "attachments")
      
      # Add generated assets
      @environment.append_path @storage.path(:cache, "assets")
      
      # Theme, plugins, vendor and customisation
      [
        self.theme.path,
        *plugins.collect{|name, plugin| plugin.asset_path},
        ::File.join(File.dirname(__FILE__), "..", "..", "vendor"),
      ].each do |path|
        %w{javascripts stylesheets images}.each {|p|
          @environment.append_path ::File.join(path, "assets", p)
        }
      end
      
      # Customisation
      %w{javascripts stylesheets images}.each do |path|
        @environment.prepend_path @storage.path(:custom, path)
      end
    end
    
    def load_content
      say "==> Loading site content"
      
      # Read site content
      @content = Content.new(site: self)
      @content.load

      # Do we have index page defined
      if self.config.index
        index_page = @content.by_slug(self.config.index)
        if index_page
          index_page.metadata.slug = "index"
          index_page.metadata.template = "/:locale/:slug"
          index_page.metadata.title = Hash[index_page.metadata.languages.collect{|lang| [lang, metadata.title(lang)]}]
        end
      end
    end
    
    def process_attachments
      puts "==> Processing attachments"
      
      progress.create :attachments, title: "Attachments", total: self.content.attachments.count
      progress.display
      
      @@lock = Mutex.new
      
      Parallel.map(self.content.attachments, :in_threads => Parallel.processor_count) do |attachment|
        if processor = attachments.get(attachment)
          processor.process
        end
        @@lock.synchronize do
          progress.step(:attachments)
        end
      end
      
      progress.finish(:attachments)
      progress.hide
      
      # DEBUG
      require 'json'
      File.open(self.storage.path(:cache) + "/mapping.json", 'w') {|io| io.puts self.attachments.mapping.to_json}
    end
    
    def compile_assets
      puts "==> Compiling assets"
      
      # Generate stylesheet
      @storage.output(:cache, "assets/style.css") do |io|
        io.puts "/*"
        
        # Theme style
        io.puts " *= require #{self.config.theme}"
        
        # Plugins
        @plugins.each do |name, plugin|
          io.puts " *= require #{name}"
        end
        
        # Blog customization
        @storage.custom(/stylesheets\/.*.css.*$/).each do |name, item|
          name = File.basename(name).gsub(/(\.\S+)$/, '')
          io.puts " *= require #{name}"
        end
        
        io.puts "*/"
      end
      # Add stlesheet to template
      Alula::Plugin.addon(:head, ->(context){ context.stylesheet_link("style") })
      
      # Generate javascript
      @storage.output(:cache, "assets/script.js") do |io|
        io.puts "/*"

        # Theme scripts
        io.puts " *= require #{self.config.theme}"

        # Plugins
        @plugins.each do |name, plugin|
          io.puts " *= require #{name}"
        end

        # Vendored
        io.puts " *= require lazyload" if self.config.attachments.image.lazyload
        io.puts " *= require emphasis" if self.config.content.emphasis

        # Customisation
        @storage.custom(/javascripts\/.*.js.*$/).each do |name, item|
          name = File.basename(name).gsub(/(\.\S+)$/, '')
          io.puts " *= require #{name}"
        end
        io.puts " */"
      end
      # Add javascript to end of body
      Alula::Plugin.addon(:body, ->(context){ context.javascript_link("script", async: true) })
      
      # Compile all assets
      progress.create :assets, title: "Compiling assets", total: @environment.each_logical_path.count
      progress.display
      
      @manifest = Manifest.new(@environment, @storage.path(:assets))
      @manifest.progress = -> { progress.step(:assets) }
      
      @manifest.compile

      progress.finish(:assets)
      progress.hide
    end
    
    def render
      say "==> Render site"
      
      progress.create :render, title: "Rendering content", total: (self.content.posts.count + self.content.pages.count)
      progress.display
      
      # Render all user content, parallel...
      (self.content.posts + self.content.pages).each do |content|
        # Write content to file
        content.write
        
        progress.title(:render, "%20s" % content.name[0..19]) if self.config.debug
        progress.step(:render)
      end
      
      progress.finish(:render)
      
      # Copy static content
      progress.create :static, title: "Copy statics", total: self.content.statics.count
      self.content.statics.each do |static|
        @storage.output_public(static.name) { |io| io.write(static.read) }
        
        progress.step :static
      end
      progress.finish :static
      
      progress.hide
    end
    
    def cleanup
      say "==> Cleaning up"
      
      asset_path = @storage.path(:assets)
      assets = @environment.used
        .collect{|u| @environment[u]}
        .reject{|u| u.nil?}
        .collect{|u| File.join(asset_path, u.digest_path)}
      outputted = @storage.outputted.reject{|o|o[/^#{asset_path}/]}
      
      keep = assets + outputted
      Dir[File.join(@storage.path(:public), "**", "*")].each do |entry|
        next unless File.file?(entry)
        FileUtils.rm entry if File.file?(entry) and !keep.include?(entry)
      end
      
      # Clean up empty directories
      Dir[File.join(@storage.path(:public), "**", "*")].each do |entry|
        next unless File.directory?(entry)
        FileUtils.rmdir entry if Dir[File.join(entry, "**", "*")].count == 0
      end
    end
    
    # Output helpers
    def say(msg)
      @shell ||= Thor::Shell::Basic.new
      @shell.say msg
    end
  end
end
