require 'mimemagic'
require 'mini_exiftool'

module Alula
  class Processor
    attr_reader :item
    attr_reader :options
    attr_reader :site
    attr_reader :attachments
    
    def self.mimetype(*mimetypes)
      (class << self; self; end).send(:define_method, "mimetypes") do
        mimetypes.collect do |m|
          if m.kind_of?(String)
            Regexp.new("^#{m}$")
          else
            m
          end
        end
      end
    end
    
    def self.available?(options)
      true
    end
    
    def self.process?(item, opts)
      if self.respond_to?(:mimetypes)
        mimetype = if opts[:fast]
          MimeMagic.by_extension(item.extension)
        else
          MimeMagic.by_magic(File.open(item.filepath))
        end
        
        return !(self.mimetypes.select{|re| re.match(mimetype.type)}.empty?)
      end
      
      return false
    end
    
    def initialize(item, opts)
      @item = item
      @site = opts.delete(:site)
      @attachments = opts.delete(:attachments)
      
      @options = opts.delete(:options)
      
      # Networked processors, create global 'queues' to prevent multiple simultanous upload/downloads
      @@upload ||= Mutex.new
      @@download ||= Mutex.new
    end
    
    def cleanup
      @item = nil
    end
    
    def process
    end
    
    def asset_path(name, type)
      asset_name = self.attachments.asset_name(name, type.to_s)
      output = File.join(self.site.storage.path(:cache, "attachments"), asset_name)
      # Make sure our directory exists
      output_dir = self.site.storage.path(:cache, "attachments", File.dirname(asset_name))
      
      output
    end
    
    def info
      @info ||= begin
        info = Dimensions.dimensions(self.item.filepath)
        info ||= begin
          _info = MiniExiftool.new self.item.filepath
          [_info.imagewidth, _info.imageheight]
        end
        Hashie::Mash.new({
          width: info[0],
          height: info[1],
        })
      end
    end
    
  end
end

Dir[File.dirname(__FILE__) + '/processors/*.rb'].each { |f| require f }
