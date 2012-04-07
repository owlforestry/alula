require 'RMagick'

module Alula
  class AssetHelper
    IMAGES = %w{jpeg jpg png gif}
    MOVIES = %w{mp4}
    
    def initialize(asset_path, options)
      @options = options
      @asset_path = asset_path
    end
    
    def process(asset, options)
      options = @options.deep_merge(options)
      
      # Resolve our asset type
      ext = File.extname(asset)[1..-1] || ""
      
      if IMAGES.include?(ext.downcase)
        [:image, process_image(asset, options)]
      elsif MOVIES.include?(ext.downcase)
        [:movie, process_movie(asset, options)]
      else
        puts "Unknown asset type #{ext} for #{asset}"
        false
      end
    end
    
    private
    def process_image(asset, options)
      ext = File.extname(asset)[1..-1].downcase
      name = case options[:keepcase]
      when true
        File.basename(asset, ".#{ext}")
      else
        File.basename(asset, ".#{ext}").to_url
      end
      generated = []
      
      # Resolve size for new photo
      width, height = case options[:type]
      when :attachment
        options["images"]["size"].split("x").collect {|i| i.to_i }
      when :thumbnail
        options["images"]["thumbnails"].split("x").collect {|i| i.to_i }
      end
      
      file_path = case options[:type]
      when :attachment
        File.join("attachments", "_generated", "images", @asset_path)
      when :thumbnail
        File.join("attachments", "_generated", "thumbnails", @asset_path)
      end
      # Create output path
      FileUtils.mkdir_p(file_path)
      
      # Copy asset to originals
      if options[:type] == :attachment and !File.exists?(File.join("attachments", "originals", @asset_path, "#{name}.#{ext}"))
        FileUtils.mkdir_p File.join("attachments", "originals", @asset_path)
        FileUtils.cp asset, File.join("attachments", "originals", @asset_path, "#{name}.#{ext}")
      end
      
      # Create normal photo
      image = Magick::Image.read(asset).first
      image_width, image_height = image.columns, image.rows
      
      resized = image.resize_to_fit(width, height)
      resized.write(File.join(file_path, "#{name}.#{ext}"))
      generated << File.join(@asset_path, "#{name}.#{ext}")
      
      # Generate retina if required
      if (options["images"]["retina"] and (image_width > width * 2) or (image_height > height * 2))
        retina = image.resize_to_fit(width * 2, height * 2)
        resized.write(File.join(file_path, "#{name}_2x.#{ext}"))
        generated << File.join(@asset_path, "#{name}_2x.#{ext}")
      end
      
      return generated
    end
  end
end
