require 'RMagick'

module Alula
  module Helpers
    class Image_ImageMagick < ImageHelper
      def initialize(asset, options)
        super

        @image = Magick::Image.read(@asset).first
        @image_width, @image_height = @image.columns, @image.rows
      end
      
      # Options[:type] == :fullsize||:thumbnail (for optimizing)
      def resize_image(width, height, options = {})
        resized = @image.resize_to_fit(width, height)
        resized.write(options[:output])
      end
    end
  end
end
