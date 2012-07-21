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
        @compressor = HtmlCompressor::Compressor.new({
          remove_surrounding_spaces: HtmlCompressor::Compressor::BLOCK_TAGS_MAX + ",source,title,meta,header,footer,div,section,article,time,img,video,script",
          remove_intertag_spaces: true,
          remove_quotes: true,
          remove_script_attributes: true,
          remove_style_attributes: true,
          remove_link_attributes: true,
          simple_boolean_attributes: true,
          remove_http_protocol: false,
          remove_https_protocol: false,
        })
      end
      
      def compress(content)
        @compressor.compress(content)
      end
    end
  end
end
