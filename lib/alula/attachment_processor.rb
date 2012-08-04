module Alula
  class AttachmentProcessor
    def self.register(name, klass); processors[name] = klass; end
    def self.processors; @@processors ||= {}; end
    def processors; self.class.processors; end
    
    attr_reader :site
    
    def initialize(opts)
      @site = opts.delete(:site)
      
      @@lock = Mutex.new
    end
    
    def mapping
      @mapping ||= {}
    end
    
    def asset_name(name, *path)
      path ||= []

      @@lock.synchronize do      
        md5 = Digest::MD5.hexdigest(name)
        asset_hash = md5[0..3]
        asset_name = File.join(path + [asset_hash]) + File.extname(name)
        until !mapping.key(asset_name) or mapping.key(asset_name) == name
          asset_hash = md5[0..(asset_hash.length)]
          asset_name = File.join(path + [asset_hash]) + File.extname(name)
        end
      
        mapping[name] = asset_name
      end
      
      mapping[name]
    end
    
    def get(item)
      # Try to use cached processor for extension
      type = _type(item)
      options = site.config.attachments[type]
      self.processors[type].new(item, options: options, site: site, attachments: self)
    end
    
    private
    def cached
      @cached ||= {}
    end
    
    def _type(item)
      if cached[item.extension] and self.processors[cached[item.extension]].process?(item, fast: true)
        return cached[item.extension]
      end
      
      types = available.collect { |t| [t, false] } + available.collect { |t| [t, true] }
      types.each do |type, fast|
        processor = self.processors[type]
        if processor.process?(item, fast: fast)
          cached[item.extension] = type
          return type
        end
      end
      
      return "dummy"
    end
    
    def available
      @@lock.synchronize do
        @available ||= begin
          self.site.config.attachments.processors.select { |p|
            options = self.site.config.attachments[p] || {}
            self.processors.has_key?(p) and self.processors[p].available?(options)
          }
        end
      end
    end
  end
end

require 'alula/processor'
