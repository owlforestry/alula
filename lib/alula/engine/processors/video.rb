require 'alula/engine/processors'

module Alula
  class Engine
    class Processors
      class Video < Processors
        extensions :mov, :mp4, :avi, :ogg, :webm
        mimetype /^video/
        
        def self.get_converter(attachment_file, options, engine)
          converter = engine.config.videos['converter']
          require "alula/engine/processors/video/#{converter}"
          klass = Alula::Engine::Processors::Video.const_get(ActiveSupport::Inflector.camelize(converter, true))
          return klass.new attachment_file, options, engine
        end
        
        def set_mapping
          name = File.basename(self.file_name, File.extname(self.file_name))
          asset_name = File.basename(self.asset_name, File.extname(self.asset_name))
          
          engine.attachment_mapping[File.join(options[:asset_path], name)] = File.join(options[:asset_path], asset_name)
        end
        
        def process
          super
          
          # Detect variants we need to generate
          # Detect video size
          size_hd = config.videos["size_hd"].split("x")
          size_sd = config.videos["size_sd"].split("x")
          tn_size = config.videos["thumbnails"].split("x")
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
            "mp4"        => { :size => size_sd, :format => "mp4" },
            "webm"       => { :size => size_sd, :format => "webm" },
            "ogg"        => { :size => size_sd, :format => "ogg" },
            "-mobile"    => { :size => size_sd, :format => "mp4", :profile => "mobile/baseline" },
            "-mobile-hd" => { :size => size_hd, :format => "mp4", :profile => "mobile/advanced" },
            "-hd"        => { :size => size_hd, :format => "mp4" },
          }
          unless @video_info.imagewidth >= 1280 and @video_info.imageheight >= 720
            variants.delete("-hd.mp4")
            variants.delete("-mobile-hd.mp4")
          end
        
          # Detect which variants has already been generated
          variants.each do |variant, opts|
            if File.exists?(File.join(options[:image_path], asset_name((variant == opts[:format] ? nil : variant), opts[:format])))
              variants.delete(variant)
            end
          end
        
          encode(variants, !File.exists?(File.join(options[:thumbnail_path], asset_name("", ".png"))))
        end
      end
    end
  end
end
