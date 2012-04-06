require 'sass'
require 'uglifier'
require 'front-compiler'

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
        @@compressor ||= Uglifier.new
        @@compressor.compress(content)
      end
    end
    
    module HTMLCompressor
      def output_with_compression
        @@compressor ||= FrontCompiler.new
        @@compressor.compact_html(@output)
      end
    end
  end
end