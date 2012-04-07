module Alula
  module Plugins
    class CommonAsset < Liquid::Tag
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
    
    class StylesheetAsset < CommonAsset
      type :css
      default :styles
      
      def content(asset)
        "<link rel=\"stylesheet\" href=\"#{asset}\" media=\"screen,projection\" type=\"text/css\">"
      end
    end

    class JavascriptAsset < CommonAsset
      type :js
      default "scripts"
      
      def content(asset)
        if File.size(File.join("public", asset)) < 10
          content = File.read(File.join("public", asset))
          unless content == ";"
            "<script type=\"text/javascript\">#{content}</script>"
          end
        else
          "<script type=\"text/javascript\" src=\"#{asset}\"></script>"
        end
      end
    end
    
    class ImageAsset < CommonAsset
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
    
    class VideoAsset < CommonAsset
      def initialize(tag_name, markup, tokens)
        # /(?<src>(?:https?:\/\/|\/|\S+\/)\S+)(?<title>\s+.+)/ =~ markup
        # /(?:"|')(?<title>[^"']+)?(?:"|')\s+(?:"|')(?<alt>[^"']+)?(?:"|')/ =~ title
        # 
        # @name = src
        # @title = title
        # @alt = alt
        @markup = markup
      end

      def render(context)
        # asset_path = context.registers[:site].config["asset_path"]
        # manifest = context.registers[:site].config["manifest"]
        # 
        # asset = File.join(asset_path, manifest.assets[@name])
        # 
        # # Fetch image size
        # img = Magick::Image.read(File.join("public", asset)).first
        # width = img.columns
        # height = img.rows
        # 
        # "<img src=\"#{asset}\" alt=\"#{@alt}\" title=\"#{@title}\" width=\"#{width}\" height=\"#{height}\">"
        "<!-- VIDEO: @markup -->"
      end
    end

    class GenericAsset < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
      end
      
      def render(context)
        require 'pry';binding.pry
      end
    end
  end
end

Liquid::Template.register_tag('asset_url', Alula::Plugins::GenericAsset)
Liquid::Template.register_tag('stylesheet_link', Alula::Plugins::StylesheetAsset)
Liquid::Template.register_tag('javascript_link', Alula::Plugins::JavascriptAsset)
Liquid::Template.register_tag('image', Alula::Plugins::ImageAsset)
Liquid::Template.register_tag('video', Alula::Plugins::VideoAsset)
