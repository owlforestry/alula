require 'alula/config'
require 'alula/content'
require 'alula/context'
require 'alula/generator'

require 'thor'

module Alula
  class Site
    # Global configuration
    attr_reader :config

    # Context for rendering
    attr_reader :context
    
    # User generated content
    attr_reader :content

    # System generated content, pages, pagination, etc.
    attr_reader :generated
    
    def initialize(options)
      # Read local config
      @config = Config.new(options)
      
      # Initialize arrays
      @generated = []
      
      # Get Thor shell
      @shell = Thor::Shell::Basic.new
      
      @context = Context.new
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
    def prepare(clean = true)
      say "==> Preparing environment" + (!clean ? "" : " (preserving existing files)")
      
      if clean
        FileUtils.rm_rf config.public_path
      end
      
      # Create required directories
      FileUtils.mkdir_p config.public_path
    end
    
    def load_content
      say "==> Loading site content"
      
      # Read site content
      @content = Content.new site: self, config: self.config
      @content.load
    end
    
    def generate_content
      say "==> Running content generators"
      
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
      
      # Render all user content, parallel...
      (self.content.posts + self.content.pages).each do |content|
        content.render
      end
      
    end
    
    # Output helpers
    def say(msg)
      @shell.say msg
    end
  end
end
