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
      
      # @context = Context.new
    end
    
    # Compiles a site to static website
    def generate
      # Prepare public folder
      prepare
      
      load_content
      
      generate_content
      
      render
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
      @content = Content.new(site: self, config: self.config)
      @content.load
    end
    
    def generate_content
      say "==> Running content generators"
      
      # Initialize generated content array
      @generated = []
      
      # Run all generators and generate required 
      @config.content.each do |type, options|
        cls_name = type[0].upcase + type[1..-1]
        cls = Alula::Generator.const_get(cls_name)
        generator = cls.new(OpenStruct.new(options), site: self, config: self.config)
        generator.generate_content
      end
    end
    
    def render
      say "==> Render site"
      
      # Load our theme
      @context = Alula::Context.new
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
