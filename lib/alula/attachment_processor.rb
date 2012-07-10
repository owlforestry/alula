module Alula
  class AttachmentProcessor
    def self.register(name, klass); processors[name] = klass; end
    def self.processors; @@processors ||= {}; end
    def processors; self.class.processors; end
    
    attr_reader :site
    
    def initialize(opts)
      @site = opts.delete(:site)
    end
    
    def mapping
      @mapping ||= {}
    end
    
    def asset_name(name, *path)
      path ||= []
      
      md5 = Digest::MD5.hexdigest(name)
      asset_hash = md5[0..3]
      until !mapping.key(asset_hash) or mapping.key(asset_hash) == name
        asset_hash = md5[0..(asset_hash.length + 1)]
      end
      
      mapping[name] = File.join(path + [asset_hash]) + File.extname(name)
      
      mapping[name]
    end
    
    def get(item)
      # Try to use cached processor for extension
      if cached[item.extension] and cached[item.extension].process?(item, fast: true)
        return cached[item.extension]
      end
      
      available.each do |t, processor|
        if processor.process?(item, fast: true)
          cached[item.extension] = processor
          return processor
        end
      end
      # Fast identify didn't worked, go through slow detection
      available.each do |t, processor|
        if processor.process?(item, fast: false)
          cached[item.extension] = processor
          return processor
        end
      end
      
      binding.pry
    end
    
    private
    def cached
      @cached ||= {}
    end
    
    def available
      @available ||= begin
        Hash[
          self.site.config.attachments["processors"]
            .select { |p| self.processors.has_key?(p) }
            .collect { |p|
              options = site.config.attachments[p]
              processor = self.processors[p].new(options, site: site, attachments: self)
              
              [p, processor]
            }
          ]
      end
    end
  end
end

require 'alula/processor'
