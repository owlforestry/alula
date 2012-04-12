require 'active_support/core_ext/hash/deep_merge'

module Alula
  class Engine
    class Config
      def self.shared(override = {})
        @@config ||= self.new(override)
      end
      
      def initialize(override = {})
        @config = DEFAULT
        if File.exists?("config.yml")
          @config.deep_merge!(YAML.load_file("config.yml"))
        end
        @config.deep_merge!(override)
      end
      
      def []=(key, value)
        @config[key] = value
      end
      
      def [](key)
        @config[key]
      end
      
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /=$/
          self.send(:[]=, meth.to_s[0..-2], *args)
        elsif @config.key?(meth.to_s)
          self.send(:[], meth.to_s)
        else
          super
        end
      end
      
      DEFAULT     = {
        # General settings
        'title'   => 'Your New Blog',
        'tagline' => 'Insert catchy subtitle here.',
        'author'  => 'Blogger',
        
        # Visual/theme
        'theme'     => 'minimal',
        'permalink' => '/:year/:month/:title/',
        
        # Plugins/Filters
        'filters'    => {
          'smilies' => {},
        },
        
        # Site options
        'images' => {
          'converter'  => 'magick',   # Use ImageMagick
          'size'       => '800x600',  # Resize images to this size
          'thumbnails' => '300x300',  # Thumbnail size
          'retina'     => true,       # Generate retina versions
          'lazyload'   => true,       # Lazy load images (also replaces retina photos)
        },
        'videos'         => {
          'size_hd'      => '1280x720',
          'size_sd'      => '640x360',
          'thumbnails'   => '300x300',
          'converter'    => 'zencoder',
          'zencoder'     => {
            'bucket'     => 'alula.zencoder',
            'token'      => '',
            'key_id'     => '',
            'access_key' => '',
          }
        },
        
        # Internal defaults, do not change
        'public_path'      => 'public',       # Where to generate site
        'assets_path'      => 'assets',       # Where to generate assets, appended to public_path
        'posts_path'       => 'posts',        # Where to get posts
        'content_path'     => 'content',      # Where to get content which name doesn't change
        'static_path'      => 'static',       # Where to get site assets, these will be hashed
        'attachments_path' => 'attachments',  # Where to store post attachments
        
        # Generation options
        'verbose'  => true, # Be verbose by default, no progress bars
        'generate' => true, # Always generate blog
        'port'     => 3000, # Use port 3000 for web server in preview mode
      }
    end
  end
end
