require 'RMagick'

module Alula
  class Engine
    class Processors
      class Image
        class Magick < Image
          def initialize(attachment_file, options, engine)
            super
            
            @image = ::Magick::Image.read(file).first
            # Always rotate image (unless disabled)
            unless options[:no_rotate]
              case @image.orientation.to_i
              when 2
                @image.flop!
              when 3
                @image.rotate!(180)
              when 4
                @image.flip!
              when 5
                @image.transpose!
              when 6
                @image.rotate!(90)
              when 7
                @image.transverse!
              when 8
                @image.rotate!(270)
              end
            end
          end
          
          def resize_image(width, height, opts = {})
            return if File.exists?(opts[:output]) and !opts[:force]
            
            # Check if our target image is bigger than source
            # Skip totally if requested
            if (width > @image.columns and height > @image.rows) and opts[:skip_nores]
              return
            end

            # Load EXIF data
            @exif ||= MiniExiftool.new file
            
            resized = @image.resize_to_fit(width, height)
            # Make it progressive
            resized.interlace = ::Magick::PlaneInterlace
            # Strip unwanted properties
            tags = Hash[*(config.images["keep_tags"].collect{|t| [t, @exif[t]]}).flatten]
            resized.strip!
            
            resized.write(opts[:output])
            
            # Save our exif data back
            exif = MiniExiftool.new opts[:output]
            tags.each {|key, value| exif[key] = value }
            exif.save
          end
        end
      end
    end
  end
end

