require 'mini_exiftool'

module Alula
  module Helpers
    class AssetHelper
      def initialize(asset, options)
        @asset = asset
        @options = options
        @asset_path = options[:asset_path]
        
        # Resolve our filename(s)
        @ext = File.extname(asset)[1..-1]
        @name = File.basename(asset, File.extname(asset))
        unless options[:keepcase]
          @ext = @ext.downcase
          @name = @name.to_url
        end
        @asset_name = File.join(@asset_path, "#{@name}.#{@ext}")
        
        # Resolve our paths
        @image_path = File.join("attachments", "_generated", "images", @asset_path)
        @thumbnail_path = File.join("attachments", "_generated", "thumbnails", @asset_path)
        @original_path = File.join("attachments", "originals", @asset_path)
        
        # Make directories
        FileUtils.mkdir_p(@image_path)
        FileUtils.mkdir_p(@thumbnail_path)
        FileUtils.mkdir_p(@original_path)
      end
      
      def self.mimetype(re)
        (class << self; self; end).send(:define_method, "mime_re") do
          re
        end
      end
      
      def self.identify(file)
        exif = MiniExiftool.new file
        exif.mimetype.match(mime_re)
      end
    end
  end
end
