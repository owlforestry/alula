module Alula
  class VideoTag < Tag
    def prepare
      @info = {}

      @options["classes"] ||= []
      @options["title"] ||= @options["alternative"]
      @options["alternative"] ||= @options["title"]
      @options["classes"] += [@options["align"] || "left"]
    end
    
    def content
      video_tag(@source)
    end
    
    def video_tag(source)
      poster = source.gsub(/#{File.extname(source)}$/, '.png')
      info = info(poster, :thumbnail)
      poster = attachment_url(poster, :thumbnail)
      
      tag = "<video"
      tag += " controls"
      tag += " class=\"#{(@options["classes"]).join(" ")}\""
      tag += " width=\"#{info.width}\""
      tag += " height=\"#{info.height}\""
      tag += " poster=\"#{poster}\""
      tag += " preload=\"none\">"
      
      sources.each do |source|
        tag += "  <source src=\"#{source[:url]}\" #{source[:hires] ? "data-quality=\"hd\"" : ""} />"
      end
      
      tag += "</video>"
    end
    
    private
    
    def sources
      @sources ||= begin
        sources = variants.collect {|variant|
          name = @source.gsub(/#{File.extname(@source)}$/, variant[:ext])
          {
            name: name,
            path: attachment_path(name, "video"),
            url: attachment_url(name, "video"),
            hires: variant[:hires],
            mobile: variant[:mobile]
          }
        }.reject{|source| source[:url].nil? }
      end
    end
    
    def variants
      @variants ||= begin
        # Collect all formats
        variants = Hash[
          self.context.site.config.attachments.video.formats.collect { |format|
            [format, {
              format: format,
              mobile: false,
              hires: false }]
          }
        ]
        # Generate mobile variants?
        if self.context.site.config.attachments.video.mobile
          variants.merge!(Hash[ variants.collect {|name, fmt| ["#{name}-mobile", fmt.merge({
            mobile: true,
          })] } ])
        end
        
        # Generate HD versions
        if self.context.site.config.attachments.video.hires
          variants.merge!(Hash[ variants.collect {|name, fmt| ["#{name}-hires", fmt.merge({
            hires: true,
          })] } ])
        end
        
        
        # Sort by preferred order
        formats = self.context.site.config.attachments.video.formats
        variants.sort {|a, b|
          # Sort by preferred format order
          c = formats.index(a.last[:format]) <=> formats.index(b.last[:format])

          # Sort HD videos on top
          c == 0 and c = (a.last[:hires] == b.last[:hires]) ? 0 : (a.last[:hires] ? -1 : 1)
          
          # Put mobile low
          c == 0 and c = (a.last[:mobile] == b.last[:mobile]) ? 0 : (a.last[:mobile] ? 1 : -1)
          
          c
        }.collect{|name, format|
          ext = (format[:mobile] ? "-mobile" : "") + (format[:hires] ? "-hires" : "") + ".#{format[:format]}"

          {ext: ext, mobile: format[:mobile], hires: format[:hires]}
        }
      end
    end
    
  end
end

Alula::Tag.register :video, Alula::VideoTag
