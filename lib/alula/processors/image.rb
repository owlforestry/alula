module Alula
  class ImageProcessor < Processor
    def process(item)
      super
      
      sizes.each do |size|
        width, height = size[:size]
        # output_dir = self.site.storage.path(:cache, "attachments", size[:type].to_s)
        
        # Generate attachment hash
        name = File.join size[:type].to_s, if size[:hires]
          ext = File.extname(item.name)
          item.name.gsub(/#{ext}$/, "-hires#{ext}")
        else
          item.name
        end
        
        asset_name = self.attachments.asset_name(name, size[:type].to_s)
        output = File.join(self.site.storage.path(:cache, "attachments"), asset_name)
        # Make sure our directory exists
        output_dir = self.site.storage.path(:cache, "attachments", File.dirname(asset_name))
        
        # Skip image processing if output already exists...
        next if File.exists?(output)
        
        # Skip if our original resolution isn't enough for hires images
        next if (width > self.info.width and height > self.info.height) and size[:hires]
        
        # Generate resized image to output path
        resize_image(output: output, size: size[:size])
      end
      
      # Cleanup ourself
      cleanup
    end
    
    def sizes
      @sizes ||= begin
        sizes = []
        sizes << { type: :image,  hires: false, size: self.site.config.attachments["image"]["size"].split("x").collect{|i| i.to_i} }
        sizes << { type: :thumbnail, hires: false, size: self.site.config.attachments["image"]["thumbnail"].split("x").collect{|i| i.to_i} }
        
        if self.site.config.attachments["image"]["hires"]
          sizes += sizes.collect {|s| { type: s[:type], hires: true, size: s[:size].collect{|x| x*2} } }
        end
        
        sizes
      end
    end
  end
end