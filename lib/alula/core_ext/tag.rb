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
      @markup = markup
      @tokens = tokens
      
      prepare if respond_to?("prepare")
    end
    
    def render(context)
      @context = context
      content if respond_to?("content")
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
