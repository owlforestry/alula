require 'sass'
require 'uglifier'

module Alula
  module Compressors
    class CSSCompressor
      def compress(content)
        if content.count("\n") > 2
          Sass::Engine.new(content,
            :syntax => :scss,
            :cache => false,
            :read_cache => false,
            :style => :compressed).render
        else
          content
        end
      end
    end
    
    class JSCompressor
      def compress(content)
        Uglifier.new.compress(content)
      end
    end
  end
end