require 'alula/helpers/assethelper'

module Alula
  module Helpers
    class ImageHelper < AssetHelper
      mimetype /^image/
      
      def process
        # Copy original
        if !File.exists?(File.join(@original_path, "#{@name}.#{@ext}"))
          puts "--> Copying original"
          FileUtils.cp @asset, File.join(@original_path, "#{@name}.#{@ext}")
        end
        
        # Detect if we need to generate full-size image
        full_size = File.join(@image_path, "#{@name}.#{@ext}")
        unless File.exists?(full_size)
          puts "--> Generating full-size image"
          width, height = @options["images"]["size"].split("x").collect {|i| i.to_i }
          resize_image(width, height, :output => full_size, :type => :fullsize)
        end
        # Retina support
        output2x = File.join(@image_path, "#{@name}_2x.#{@ext}")
        unless File.exists?(output2x)
          width, height = @options["images"]["size"].split("x").collect {|i| i.to_i }
          if @options['images']['retina'] and (@image_width > width * 2) or (@image_height > height * 2)
            puts "--> Generating full-size image (2x)"
            resize_image(width * 2, height * 2, :output => output2x, :type => :fullsize)
          end          
        end
        
        # Thumbnail
        tn_size = File.join(@thumbnail_path, "#{@name}.#{@ext}")
        unless File.exists?(tn_size)
          puts "--> Generating thumbnail image"
          width, height = @options["images"]["thumbnails"].split("x").collect {|i| i.to_i }
          resize_image(width, height, :output => tn_size, :type => :thumbnail)
        end
        # Retina support
        tn2x = File.join(@thumbnail_path, "#{@name}_2x.#{@ext}")
        unless File.exists?(tn2x)
          width, height = @options["images"]["thumbnails"].split("x").collect {|i| i.to_i }
          if @options['images']['retina'] and (@image_width > width * 2) or (@image_height > height * 2)
            puts "--> Generating thumbnail image (2x)"
            resize_image(width * 2, height * 2, :output => tn2x, :type => :thumbnail)
          end          
        end
        
        return @asset_name # Processing done
      end
      
      def self.process(asset, options)
        case options['images']['converter']
        when 'imagemagick'
          require 'alula/helpers/image_imagemagick'
          return Alula::Helpers::Image_ImageMagick.new(asset, options).process
        else
          raise "Unknown converter #{options['images']['converter']}"
        end
      end
    end
  end
end