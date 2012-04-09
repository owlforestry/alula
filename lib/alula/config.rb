module Alula
  class Config
    def self.init(override = {})
      if File.exists?('config.yml')
        config_yml = YAML.load_file('config.yml')
      end
      
      @@config = DEFAULTS.deep_merge(config_yml || {}).deep_merge(override)
    end
    
    def self.fetch
      @@config || {}
    end
    
    def self.method_missing(meth, *args, &block)
      if @@config[meth.to_s]
        @@config[meth.to_s]
      else
        super
      end
    end
    
    DEFAULTS = {
      'theme'          => 'minimal',
      'root'           => '/',
      'permalink'      => '/:year/:month/:title',
      'paginate'       => 10,
      'pagination_dir' => '/page/',
    
      'images'       => {
        'size'       => '800x600',
        'thumbnails' => '300x300',
        'retina'     => true,
        'converter'  => 'imagemagick',
      },
      'videos'       => {
        'size_hd'    => '1280x720',
        'size_sd'    => '640x360',
        'thumbnails' => '300x300',
        'converter'  => 'zencoder',
        'zencoder'   => { 'bucket' => 'alula.zencoder' }
      }
    }
  end
end
