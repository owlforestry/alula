require 'mimemagic'

module Alula
  class Processor
    attr_reader :item
    attr_reader :options
    attr_reader :site
    attr_reader :attachments
    
    def self.mimetype(*mimetypes)
      (class << self; self; end).send(:define_method, "mimetypes") do
        mimetypes
      end
    end
    
    def initialize(options, opts)
      @site = opts.delete(:site)
      @attachments = opts.delete(:attachments)
      
      @options = options
    end
    
    def process?(item, opts)
      if self.class.respond_to?(:mimetypes)
        mimetype = if opts[:fast]
          MimeMagic.by_extension(item.extension)
        else
          MimeMagic.by_magic(File.open(item.filepath))
        end

        return self.class.mimetypes.include?(mimetype.type)
      end
      
      return false
    end
    
    def cleanup
      @item = nil
    end
    
    def process(item)
      @item = item
    end
  end
end

Dir[File.dirname(__FILE__) + '/processors/*.rb'].each { |f| require f }
