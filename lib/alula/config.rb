module Alula
  class Config
    def self.init(override)
      @@config = YAML.load_file('config.yml').deep_merge(override)
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
  end
end
