require 'alula/core_ext'

require 'alula/config'
require 'alula/content'
require 'alula/context'
require 'alula/generator'
require 'alula/attachment_processor'
require 'alula/cdn'
require 'alula/storage'
require 'alula/helpers'
require 'alula/progress'

require 'thor'
require 'sprockets'
require 'i18n'
require 'parallel'

module Alula
  class Site
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
      })
      
      # Progress displayer
      @progress = Progress.new(debug: options["debug"])
      
      @attachments = AttachmentProcessor.new(site: self)
      
      # Set up CDN resolver
      @cdn = CDN.load(site: self)
      
      # Set up I18n
      l10n_path = File.join(File.dirname(__FILE__), "..", "..", "locales", "l10n", "*.yml")
      locale_path = File.join(File.dirname(__FILE__), "..", "..", "locales", "*.yml")
      I18n.load_path += Dir[l10n_path]
      I18n.load_path += Dir[locale_path]
      I18n.default_locale = @config.locale
    end
    
    # Compiles a site to static website
    def generate
      # Prepare public folder
      prepare
      
      load_content
      
      process_attachments
      
      compile_assets
      
      render
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
    def prepare(preserve = false)
      say "==> Preparing environment" + (preserve ? " (preserving existing files)" : "")
      
      # Delegate preparations to storage module
      self.storage.prepare(preserve)
      
      # Load theme
      @context = Alula::Context.new(site: self, storage: self.storage)
      @context.send(:extend, Helpers)
      
      @theme = Alula::Theme.load(site: self)
      
      # Create our asset environment
      @environment = Sprockets::Environment.new
      @context.environment = @environment
      @context.attachments = self.attachments
      
      # Add generated attachements
      @environment.append_path @storage.path(:cache, "attachments")
      
      # Add generated assets
      @environment.append_path @storage.path(:assets)
      
      # Add theme
      %w{stylesheets javascripts images}.each do |path|
        @environment.append_path ::File.join(self.theme.path, path)
      end
      
      # Plugins
      # Attachements
      # Customisation
      %w{stylesheets javascripts images static}.each do |path|
        @environment.append_path @storage.path(:custom, path)
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
      
      # pbar = ProgressBar.new "Attachments", self.content.attachments.count
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
      @storage.output("assets/style.css") do |io|
        io.puts "/*"
        
        # Theme style
        io.puts " *= require #{self.config.theme}"
        
        # Plugins
        
        # Blog customization
        if @storage.custom("stylesheets/custom.css")
          io.puts " *= require custom"
        end
        
        io.puts "*/"
      end
      
      # Compile all assets
      progress.create :assets, title: "Compiling assets", total: @environment.each_logical_path.count
      progress.display
      
      @manifest = Manifest.new(@environment, @storage.path(:assets))
      @manifest.progress = -> {
        progress.step(:assets)
      }

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
        
        progress.step(:render)
      end
      
      progress.finish(:render)
      progress.hide
    end
    
    # Output helpers
    def say(msg)
      @shell ||= Thor::Shell::Basic.new
      @shell.say msg
    end
  end
end
