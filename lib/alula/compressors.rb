require 'sass'
require 'uglifier'
require 'htmlcompressor'

module Alula
  class Compressors
    class DummyCompressor
      def compress(content)
        content
      end
    end
    
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
      def initialize
        @compressor = Uglifier.new
      end
      
      def compress(content)
        @compressor.compress(content)
      end
    end
    
    class HTMLCompressor
      def initialize
        @compressor = HtmlCompressor::Compressor.new
      end
      
      def compress(content)
        @compressor.compress(content)
      end
    end
  end
end
