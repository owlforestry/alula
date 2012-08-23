require 'alula/processors/image'
require 'hashie/mash'
require 'RMagick'
require 'mini_exiftool'

module Alula
  class Magick < ImageProcessor
    # Register mimetypes
    mimetype "image/jpeg", "image/png", "image/gif"
    
    def resize_image(opts)
      output = opts[:output]
      width, height = opts[:size]
      
      # Generate resized image
      resize_mode = self.site.config.attachments.image["#{opts[:type]}_mode"]
      resized = case resize_mode
      when :square
        self.image.resize_to_fill(width, height)
      else
        self.image.resize_to_fit(width, height)
      end
      # Make it progressive
      resized.interlace = ::Magick::PlaneInterlace
      
      # Strip unwanted properties
      tags = Hash[*(self.site.config.attachments["image"]["keep_tags"].collect{|t| [t, self.exif[t]]}).flatten]
      resized.strip!
      
      resized.write(output)
      
      # Save our EXIF info
      exif = MiniExiftool.new output
      tags.each {|key, value| exif[key] = value }
      exif.save
    end
    
    def cleanup
      super
      
      @info = nil
      @image = nil
      @exif = nil
    end
    
    def info
      @info ||= begin
        info = ::Magick::Image.ping(self.item.filepath).first
        Hashie::Mash.new({
          width: info.columns,
          height: info.rows,
        })
      end
    end
    
    def exif
      @exif ||= MiniExiftool.new self.item.filepath
    end
    
    def image
      @image ||= begin
        image = ::Magick::Image.read(self.item.filepath).first
        unless self.options[:no_rotate]
          case image.orientation.to_i
            when 2
              image.flop!
            when 3
              image.rotate!(180)
            when 4
              image.flip!
            when 5
              image.transpose!
            when 6
              image.rotate!(90)
            when 7
              image.transverse!
            when 8
              image.rotate!(270)
          end
          
          image
        end
      end
    end
    
  end
end

Alula::AttachmentProcessor.register('magick', Alula::Magick)
