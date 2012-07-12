require 'liquid'

module Alula
  module LiquidExt
    attr_reader :context

    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def register(tagname, klass)
        Liquid::Template.register_tag(tagname.to_s, klass)
      end
    end
    
    def initialize(tagname, markup, tokens)
      super
      
      @tagname = tagname
      @markup = markup.strip
      @tokens = tokens
      
      @info = {}
      
      prepare if respond_to?("prepare")
    end
    
    def render(context)
      @context = context
      if respond_to?("content")
        content
      else
        super
      end
    end
    
    private
    def info(source, type = nil)
      @info["#{source}#{type.to_s}"] ||= begin
        file = self.context.asset_path(attachment_path(source, type))
        info = MiniExiftool.new File.join self.context.storage.path(:public), file
        Hashie::Mash.new({
          width: info.imagewidth,
          height: info.imageheight,
        })
      end
    end
    
    def attachment_path(source, type = nil)
      name = (type.nil?) ? source : File.join(type.to_s, source)
      self.context.attachments.mapping[name]
    end
    
    def attachment_url(source, type = nil)
      self.context.asset_url(attachment_path(source, type))
    end
    
  end
  
  class Tag < Liquid::Tag
    include LiquidExt
  end
  
  class Block < Liquid::Block
    include LiquidExt
  end
end

Dir[File.join(File.dirname(__FILE__), "tags", "*.rb")].each {|f| require f}