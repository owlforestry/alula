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
      author: "",
      # The blog description
      description: "",
      # The host where blog is available
      url: "http://localhost:3000",
      
      # Base locale which is used is no other locale defined
      locale: "en",
      hides_base_locale: true, # Hide default locale
      
      # Default theme
      theme: {'minimal' => {}},
      
      # Template for generating post permalinks
      permalinks: '/:locale/:year/:month/:title/',
      # Template for generating pages paths
      pagelinks: '/:locale/:slug',
      
      # Directories and storage
      storage: {
        file: {
          content_path:     'content',
          pages_path:       'content/pages',
          posts_path:       'content/posts',
          attachments_path: 'content/attachments',
          static_path:      'content/static',
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
      
      # Plugins
      plugins: {},
      
      # Cookie consent
      cookieconsent: {
        consenttype: "implicit",
        style: "light",
        bannerPosition: "push",
        onlyshowbanneronce: true,
        privacysettingstab: false,
        ipinfodbkey: "",
      },
      
      # Deployment options
      deployment: { "package" => {}},
      
      # Blog Content options
      content: {
        generators: {
          paginate: {
               items: 10,
            template: "/:locale/page/:page/",
          },
          feedjson: {
               items: 10,
                name: "feed.json",
                slug: "feedjson",
            template: "/:locale/:name",
          },
          feedbuilder: {
                  items: 10,
                   name: "feed.xml",
                   slug: "feed",
               template: "/:locale/:name",
          },
          sitemap: {},
          archive: {
             template: "/:locale/:name/",
            templates: [
              "/:year/",
              "/:year/:month/",
            ],
          },
        },
        filters: {
          smilies: nil,
        },
        sidebar: [ :pages, :languages ],
      },
      
      assets: {
        production: {
          compress: true,
          gzip: true,
        },
      },
      gzip_types: [ "js", "css", "xml", "html", "ttf", "svg", "eot" ],
      
      # Attachement Processors
      attachments: {
        "image" => {
          "size"           => "800x600",
          "thumbnail"      => "300x300",
          "thumbnail_mode" => :aspect,
          "image_mode"     => :aspect,
          "keep_tags"      => ["CopyrightNotice", "Title", "DateTimeOriginal"],
          "hires"          => true,
          "lazyload"       => true,
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
