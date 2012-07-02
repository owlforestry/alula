require 'ostruct'
require 'alula/support/deep_merge'

module Alula
  class Config
    def initialize(override = {}, config_file = "config.yml")
      # Load default configuration
      config = DEFAULT_CONFIG.dup
      
      # Load project specific configuration
      if (File.exists?(config_file))
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
      title: "The Unnamed Blog",
      url: "http://localhost:3000",
      cdn: nil,
      asset_host: nil,
      
      permalinks: '/:year/:month/:title/',
      
      # Directories
      # Content directories
      content_path: 'content',
      pages_path: 'content/pages',
      posts_path: 'content/posts',
      attachements_path: 'content/attachements',
      
      # Public & Generated paths
      public_path: 'public',
      
    }.freeze
  end
end
