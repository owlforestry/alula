require 'alula/helpers/assethelper'

module Alula
  module Helpers
    class MovieHelper < AssetHelper
      extensions :mov, :mp4, :avi, :ogg, :webm
      mimetype /^video/
      
      def process
        # Copy original
        if !File.exists?(File.join(@original_path, "#{@name}.#{@ext}"))
          puts "--> Copying original"
          FileUtils.cp @asset, File.join(@original_path, "#{@name}.#{@ext}")
        end
        
        # Detect variants we need to generate
        # Detect video size
        size_hd = @options["videos"]["size_hd"].split("x")
        size_sd = @options["videos"]["size_sd"].split("x")
        tn_size = @options["videos"]["thumbnails"].split("x")
        # Check if we have portrait video
        if @video_info.rotation == 90 or @video_info.rotation == 270
          size_hd.reverse!
          size_sd.reverse!
          tn_size.reverse!
        end
        size_hd = size_hd.join("x")
        size_sd = size_sd.join("x")
        tn_size = tn_size.join("x")
        
        variants = {
          "mp4"            => { :size => size_sd },
          "webm"           => { :size => size_sd },
          "ogg"            => { :size => size_sd },
          "-mobile.mp4"    => { :size => size_sd, :profile => "mobile/baseline" },
          "-mobile-hd.mp4" => { :size => size_hd, :profile => "mobile/advanced" },
          "-hd.mp4"        => { :size => size_hd },
        }
        unless @video_info.imagewidth >= 1280 and @video_info.imageheight >= 720
          variants.delete("-hd.mp4")
          variants.delete("-mobile-hd.mp4")
        end
        
        # Detect which variants has already been generated
        variants.each do |variant, opt|
          if File.exists?(File.join(@image_path, "#{@name}#{File.extname(variant).empty? ? "." : ""}#{variant}"))
            variants.delete(variant)
          end
        end
        
        encode(variants, !File.exists?(File.join(@thumbnail_path, "#{@name}.png")))
        
        return File.join(@asset_path, "#{@name}")
      end
      
      def self.process(asset, options)
        case options['videos']['converter']
        when 'zencoder'
          require 'alula/helpers/movie_zencoder'
          return Alula::Helpers::Movie_Zencoder.new(asset, options).process
        else
          raise "Unknown converter #{options['videos']['converter']}"
        end
      end
    end
  end
end
