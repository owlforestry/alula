require 'RMagick'

module Alula
  module Plugins
    class GenericAsset < Liquid::Tag
      def self.type(type)
        define_method(:type) { type }
      end
      
      def self.default(default)
        define_method(:default) { default }
      end
      
      def initialize(tag_name, markup, tokens)
        super
        
        /(?<name>\w+)/ =~ markup
        @name = "#{name || default}.#{type}"
      end
      
      def render(context)
        asset_path = context.registers[:site].config["asset_path"]
        manifest = context.registers[:site].config["manifest"]
        
        content(File.join(asset_path, manifest.assets[@name]))
      end
    end
    
    class StylesheetAsset < GenericAsset
      type :css
      default :styles
      
      def content(asset)
        "<link rel=\"stylesheet\" href=\"#{asset}\" media=\"screen,projection\" type=\"text/css\">"
      end
    end

    class JavascriptAsset < GenericAsset
      type :js
      default "scripts"
      
      def content(asset)
        "<script type=\"text/javascript\" src=\"#{asset}\"></script>"
      end
    end
    
    class ImageAsset < GenericAsset
      def initialize(tag_name, markup, tokens)
        /(?<src>(?:https?:\/\/|\/|\S+\/)\S+)(?<title>\s+.+)/ =~ markup
        /(?:"|')(?<title>[^"']+)?(?:"|')\s+(?:"|')(?<alt>[^"']+)?(?:"|')/ =~ title
        
        @name = src
        @title = title
        @alt = alt
      end

      def render(context)
        asset_path = context.registers[:site].config["asset_path"]
        manifest = context.registers[:site].config["manifest"]
        
        asset = File.join(asset_path, manifest.assets[@name])
        
        # Fetch image size
        img = Magick::Image.read(File.join("public", asset)).first
        width = img.columns
        height = img.rows
        
        "<img src=\"#{asset}\" alt=\"#{@alt}\" title=\"#{@title}\" width=\"#{width}\" height=\"#{height}\">"
      end
    end
  end
end


Liquid::Template.register_tag('stylesheet_link', Alula::Plugins::StylesheetAsset)
Liquid::Template.register_tag('javascript_link', Alula::Plugins::JavascriptAsset)
Liquid::Template.register_tag('image', Alula::Plugins::ImageAsset)