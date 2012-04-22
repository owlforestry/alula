require 'liquid'

module Alula
  class Engine
    class Plugins
      class Tag < Liquid::Tag
        attr_reader :context
        
        def self.register(tagname)
          Liquid::Template.register_tag(tagname.to_s, self)
        end
        
        def initialize(tag_name, markup, tokens)
          super
          
          if respond_to?("prepare")
            prepare(markup, tokens)
          end
        end
        
        def render(context)
          @context = context
          if respond_to?("content")
            content(context)
          end
        end
      end
    end
  end
end
