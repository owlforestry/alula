require 'hashie/mash'

module Alula
  class Config
    def initialize(override = {}, config_file = "config.yml")
      @config = Hashie::Mash.new
      @_used = Hashie::Mash.new # Keep track of applied configuration
      
      # Load default configuration
      @config.update(DEFAULT_CONFIG)
      
      # Load project specific configuration
      @config.update(YAML.load_file(config_file)) if ::File.exists?(config_file)
      
      # Load overrides
      @config.update(override)
    end
    
    def write_cache(file)
      File.open(file, 'w') {|io| io.puts JSON.parse(@_used.to_json).to_yaml }
    end
    
    def method_missing(meth, *args, &blk)
      if meth[/=$/]
        @config.send(meth, *args)
      else
        value = @config.send(:[], meth)
        if value.kind_of?(Hashie::Mash)
          # Try environment
          value = value[environment] if value.has_key?(environment)
        end
        @_used.send("#{meth}=", value)
        
        value
      end
    end
    
    private
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
        file: {
          content_path:     'content',
          pages_path:       'content/pages',
          posts_path:       'content/posts',
          attachments_path: 'content/attachments',
          custom_path:      'custom',
          cache_path:       'cache',
          public_path:      'public',
        }
      },
      
      # CDN Configuration
      cdn: {
        development: { hosts: ["/"] },
         production: { hosts: ["/"] },
      },
      
      # Content generators
      generators: {
        paginate: {
          items: 10,
          template: "/:locale/page/:page/",
        },
        feedbuilder: {
          items: 10,
        },
      },
      
      # Attachement Processors
      attachments: {
        "image" => {
          "size"      => "800x600",
          "thumbnail" => "300x300",
          "keep_tags" => ["CopyrightNotice", "Title", "DateTimeOriginal"],
          "hires"     => true,
        },
        "video" => {
          "size-hd"        => "1280x720",
          "size-mobile-hd" => "1280x720",
          "size-sd"        => "640x360",
          "size-mobile-sd" => "640x360",
          "thumbnail"      => "300x300",            
          "formats"        => ["mp4", "webm", "ogg"],
          "hires"          => true,
          "mobile"         => true,
        },
        "audio" => {},
        
        "processors" => ["magick", "zencoder"],
        "magick"     => {},
        "zencoder"   => {
          "bucket" => "alula.attachments",
        }
      }
    }
  end
end
