require 'sass'
require 'uglifier'
require 'htmlcompressor'

module Alula
  class Compressors
    class DummyCompressor
      def compresses?(item)
        return false
      end
      
      def compress(content)
        content
      end
    end
    
    class CSSCompressor
      def compresses?(item)
        return true
      end      
      
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
      
      def compresses?(item)
        return true
      end
      
      def compress(content)
        @compressor.compress(content)
      end
    end
    
    class HTMLCompressor
      def initialize
        HtmlCompressor::Compressor.send(:include, HTMLCompressorExt)
        @compressor = HtmlCompressor::Compressor.new#({
        #   remove_surrounding_spaces: HtmlCompressor::Compressor::BLOCK_TAGS_MAX + ",source,title,meta,header,footer,div,section,article,time,img,video,script",
        #   remove_intertag_spaces: true,
        #   remove_quotes: true,
        #   remove_script_attributes: true,
        #   remove_style_attributes: true,
        #   remove_link_attributes: true,
        #   simple_boolean_attributes: true,
        #   remove_http_protocol: false,
        #   remove_https_protocol: false,
        # })
        @compressor.profile = :high
      end
      
      def compresses?(item)
        return true if item.generator.nil?
        
        return item.generator.allow_compressing? != :none
      end
      
      def compress(item, content)
        _old_profile = @compressor.profile
        unless item.generator.nil?
          @compressor.profile = item.generator.allow_compressing?
        end

        @compressor.compress(content)
      ensure
        @compressor.profile = _old_profile
      end
      
      module HTMLCompressorExt
        def profile
          @profile
        end
        
        def profile=(profile)
          @profile = profile
          case profile
          when :none
            @options[:enabled] = false
          when :normal
            @options[:enabled] = true
            @options[:remove_surrounding_spaces] = HtmlCompressor::Compressor::BLOCK_TAGS_MAX + ",source,title,meta,header,footer,div,section,article,time,img,video,script"
            @options[:remove_intertag_spaces] = true
            @options[:remove_quotes] = false
            @options[:remove_script_attributes] = true
            @options[:remove_style_attributes] = true
            @options[:remove_link_attributes] = true
            @options[:simple_boolean_attributes] = true
            @options[:remove_http_protocol] = false
            @options[:remove_https_protocol] = false
          when :high
            @options[:enabled] = true
            @options[:remove_surrounding_spaces] = HtmlCompressor::Compressor::BLOCK_TAGS_MAX + ",source,title,meta,header,footer,div,section,article,time,img,video,script"
            @options[:remove_intertag_spaces] = true
            @options[:remove_quotes] = true
            @options[:remove_script_attributes] = true
            @options[:remove_style_attributes] = true
            @options[:remove_link_attributes] = true
            @options[:simple_boolean_attributes] = true
            @options[:remove_http_protocol] = true
            @options[:remove_https_protocol] = true
          end
        end
      end
    end
  end
end
