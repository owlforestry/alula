require 'alula/storages/filestorage'

module Alula
  class Storage
    attr_reader :options
    
    def self.load(opts = {})
      site = opts[:site]
      
      # Get storage class
      # puts "--> #{site.config.storage}"
      type = site.config.storage.keys.last
      cls_name = type[0].upcase + type[1..-1] + "Storage"
      if self.const_defined?(cls_name)
        cls = self.const_get(cls_name)
        return cls.new(site.config.storage[type], opts)
      else
        return nil
      end
    end
    
    def initialize(options, opts = {})
      @options = options
      @site = opts[:site]
    end
    
    def post(name)
      self.posts[name]
    end
    
    def page(name)
      self.pages[name]
    end
    
    def custom(name)
      self.customs[name]
    end
  end
end
