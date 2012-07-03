require 'ostruct'
require 'alula/support/deep_merge'

module Alula
  class Config
    def initialize(override = {}, config_file = "config.yml")
      # Load default configuration
      config = DEFAULT_CONFIG.dup
      
      # Load project specific configuration
      if (::File.exists?(config_file))
        config.deep_merge!(YAML.load_file(config_file))
      end
      
      # Load overrides
      config.deep_merge!(override)
      
      @config = OpenStruct.new(config)
    end
    
    def method_missing(meth, *args, &blk)
      @config.send(meth, *args)
    end
    
    DEFAULT_CONFIG = {
      # The title of the blog
      title: "The Unnamed Blog",
      # Tagline of the blog
      tagline: "This has no tagline.",
      # The author, default
      author: "John Doe",
      # The host where blog is available
      url: "http://localhost:3000",
      
      # Base locale which is used is no other locale defined
      locale: "en",
      hides_base_locale: true, # Hide default locale
      
      # Default theme
      theme: 'minimal',
      
      # Template for generating post permalinks
      permalinks: '/:locale/:year/:month/:title/',
      # Template for generating pages paths
      pagelinks: '/:locale/:title/',
      
      # Directories and storage
      storage: {
        "file" => {
          "content_path"      => 'content',
          "pages_path"        => 'content/pages',
          "posts_path"        => 'content/posts',
          "attachements_path" => 'content/attachements',
          "public_path"       => 'public',
        }
      },
      
      # Content generators, by default none
      content: []
    }.freeze
  end
end
