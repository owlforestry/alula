require 'alula/config'
require 'alula/content'
require 'alula/context'
require 'alula/generator'
require 'alula/storage'

require 'thor'

module Alula
  class Site
    # Global configuration
    attr_reader :config
    
    # Storage
    attr_reader :storage
    
    # Context for rendering
    attr_reader :context
    
    # Site metadata information
    attr_reader :metadata
    
    # Theme
    attr_reader :theme
    
    # User generated content
    attr_reader :content

    # System generated content, pages, pagination, etc.
    attr_reader :generated
    
    def initialize(options)
      # Read local config
      @config = Config.new(options)
      
      @storage = Alula::Storage.load(site: self)
      
      @metadata = Alula::Content::Metadata.new({
        base_locale: @config.locale,
        
        title: @config.title,
        author: @config.author,
        tagline: @config.tagline,
        url: @config.url,
      })
    end
    
    # Compiles a site to static website
    def generate
      # Prepare public folder
      prepare
      
      load_content
            
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
        end
      end
    end
    
    def render
      say "==> Render site"
      
      # Load our theme
      @context = Alula::Context.new(site: self)
      @theme = Alula::Theme.load(site: self)
      
      # Render all user content, parallel...
      (self.content.posts + self.content.pages).each do |content|
        # Write content to file
        content.write
      end
      
    end
    
    # Output helpers
    def say(msg)
      @shell ||= Thor::Shell::Basic.new
      @shell.say msg
    end
  end
end
