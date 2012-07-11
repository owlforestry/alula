require 'hashie/mash'

module Alula
  class Config
    def initialize(override = {}, config_file = "config.yml")
      # Load default configuration
      @config = Hashie::Mash.new(DEFAULT_CONFIG)
      
      # Load project specific configuration
      if (::File.exists?(config_file))
        @config.update(YAML.load_file(config_file))
      end
      
      # Load overrides
      @config.update(override)
    end
    
    def method_missing(meth, *args, &blk)
      # @config.send(:[], *([meth] + args))
      
      if meth[/=$/]
        @config.send(meth, *args)
      else
        # Localisation support
        value = @config.send(:[], *([meth] + args))
        if value.kind_of?(Hashie::Mash)
          # Try environment & locale first
          return value[environment] if value.has_key?(environment)
        end
        
        value
      end
      
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
          "attachments_path"  => 'content/attachments',
          "custom_path"       => 'custom',
          "cache_path"        => 'cache',
          "public_path"       => 'public',
        }
      },
      
      # CDN Configuration
      cdn: {
        "hosts" => ["/"],
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
    }.freeze
  end
end
