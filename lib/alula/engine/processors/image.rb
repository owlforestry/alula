require 'alula/engine/processors'

module Alula
  class Engine
    class Processors
      class Image < Processors
        extensions :jpg, :jpeg, :png, :gif
        mimetype /^image/
        
        def self.get_converter(attachment_file, options, engine)
          converter = engine.config.images['converter']
          require "alula/engine/processors/image/#{converter}"
          klass = Alula::Engine::Processors::Image.const_get(ActiveSupport::Inflector.camelize(converter, true))
          return klass.new attachment_file, options, engine
        end
        
        def process
          super
          
          # Detect if we need to generate full-size image
          width, height = config.images["size"].split("x").collect {|i| i.to_i }
          resize_image(width, height, :output => File.join(options[:image_path], asset_name), :type => :fullsize)
          
          # Thumbnail
          width, height = config.images["thumbnails"].split("x").collect {|i| i.to_i }
          resize_image(width, height, :output => File.join(options[:thumbnail_path], asset_name), :type => :thumbnail)
          
          # Generate hi-res versions
          if config.images['hires']
            set_mapping("_2x")
            width, height = config.images["size"].split("x").collect {|i| i.to_i * 2}
            resize_image(width, height, :output => File.join(options[:image_path], asset_name("_2x")), :type => :fullsize, :skip_nores => true)

            width, height = config.images["thumbnails"].split("x").collect {|i| i.to_i * 2 }
            resize_image(width, height, :output => File.join(options[:thumbnail_path], asset_name("_2x")), :type => :thumbnail, :skip_nores => true)
          end
          
          cleanup
        end
      end
    end
  end
end
