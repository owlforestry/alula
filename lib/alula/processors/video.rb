module Alula
  class VideoProcessor < Processor
    def process
      # Select variants we need to generate
      generate = variants.select do |name, format|
        size = format[:size].split("x").collect{|i| i.to_i}
        
        # Check if video requires rotating
        if self.info.rotation == 90 or self.info.rotation == 270
          size.reverse!
        # elsif self.info.height > self.info.width  # We have pre-rotated portait video, match framesize
        #   size.reverse!
        end
        # Write rotated values back
        format[:size] = size.join("x")
        width, height = size
        
        # Generate attachment name hash
        ext = (format[:mobile] ? "-mobile" : "") + (format[:hires] ? "-hires" : "") + ".#{format[:format]}"
        name = File.join "video", item.name.gsub(/\.#{item.extension}$/, "#{ext}")
        
        output = asset_path(name, :video)
        
        format[:output] = output
        
        # Skip video processing if output already exists...
        !File.exists?(output) and !((width > self.info.width and height > self.info.height) and format[:hires])
      end
      
      # Detect if thumbnail is required
      size = self.site.config.attachments.video["thumbnail"].split("x").collect{|x|x.to_i}
      thumbnails = ([{size: size, hires: false}] + [{size: size.collect{|x| x*2}, hires: true}])
        .collect {|tn|
          if self.info.rotation == 90 or self.info.rotation == 270
            tn[:size].reverse!
          end
          tn[:size] = tn[:size].join("x")
          name = File.join "thumbnail", item.name.gsub(/\.#{item.extension}$/, "#{tn[:hires] ? "-hires" : ""}.png")
          tn[:output] = asset_path(name, :thumbnail)
          tn[:label] = "thumbnail#{tn[:hires] ? "-hires" : ""}"
          tn
        }
        .select {|tn| !tn[:hires] or (tn[:hires] and self.site.config.attachments.image.hires)}
        .select{|tn|
          width, height = tn[:size].split("x").collect{|i| i.to_i};
          !File.exists?(tn[:output]) and !((width > self.info.width and height > self.info.height) and tn[:hires])
      }
      
      thumbnails = Hash[thumbnails.collect{|tn| [tn[:label], tn]}]
      
      encode(generate, thumbnails)
    end
    
    private
    def variants
      @variants ||= begin
        # Collect all formats
        variants = Hash[
          self.site.config.attachments.video.formats.collect { |format|
            [format, {
              format: format,
              size: self.site.config.attachments.video["size-sd"],
              mobile: false,
              hires: false }]
          }
        ]
        # Generate mobile variants?
        if self.site.config.attachments.video.mobile
          variants.merge!(Hash[ variants.collect {|name, fmt| ["#{name}-mobile", fmt.merge({
            size: self.site.config.attachments.video["size-mobile-sd"],
            mobile: true,
          })] } ])
        end
        
        # Generate HD versions
        if self.site.config.attachments.video.hires
          variants.merge!(Hash[ variants.collect {|name, fmt| ["#{name}-hires", fmt.merge({
            size: (self.site.config.attachments.video[(fmt[:mobile] ? "size-mobile-hd" : "size-hd")]),
            hires: true,
          })] } ])
        end
        
        
        # Sort by preferred order
        formats = self.site.config.attachments.video.formats
        variants.sort {|a, b|
          # Sort by preferred format order
          c = formats.index(a.last[:format]) <=> formats.index(b.last[:format])

          # Sort HD videos on top
          c == 0 and c = (a.last[:hires] == b.last[:hires]) ? 0 : (a.last[:hires] ? -1 : 1)
          
          # Put mobile low
          c == 0 and c = (a.last[:mobile] == b.last[:mobile]) ? 0 : (a.last[:mobile] ? 1 : -1)
          
          c
        }
      end
    end
  end
end