require 'liquid'
require 'dimensions'

module Alula
  module LiquidExt
    attr_reader :context

    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods
      def register(tagname, klass)
        Liquid::Template.register_tag(tagname.to_s, klass)
      end
    end
    
    def initialize(tagname, markup, tokens)
      super
      
      @tagname = tagname
      @markup = markup.strip
      @tokens = tokens
      
      @info = {}
      @options = {}
      
      # Parse tag options
      if m = /^([\"][\S\. ]+[\"]|[\S\.]+)(.*)$/.match(@markup)
        @source = m[1].gsub(/^["]?([^"]+)["]?$/, '\1')
        @source = "" if @source == '""'
        @options["source"] = @source unless @source.empty?

        if m[2]
          m[2].scan(/(\S+):["]?((?:.(?!["]?\s+(?:\S+):|[>"]))+.)["]?/) do |name, value|
            @options[name] = value.strip
          end
        end
      end
      
      prepare if respond_to?("prepare")
    end
    
    def render(context)
      @context = context
      if respond_to?("content")
        content
      else
        super
      end
    end
    
    private
    def info(source, type = nil)
      @info["#{source}#{type.to_s}"] ||= begin
        file = self.context.asset_path(attachment_path(source, type))
        return Hashie::Mash.new if file.nil?
        
        info = MiniExiftool.new File.join self.context.storage.path(:public), file
        # # info = Dimensions.dimensions(File.join(self.context.storage.path(:public), file))
        # info ||= begin
        #   _info = MiniExiftool.new File.join(self.context.storage.path(:public), file)
        #   [_info.imagewidth, _info.imageheight, _info.copyrightnotice]
        # end
        Hashie::Mash.new({
          width: info.imagewidth,
          height: info.imageheight,
          rotation: info.rotation,
          copyright: info.copyrightnotice,
          filetype: info.filetype,
          title: info.title,
          caption: info.caption,
        })
      end
    end
    
    def attachment_path(source, type = nil)
      name = (type.nil?) ? source : File.join(type.to_s, source)
      self.context.attachments.mapping[name.downcase]
    end
    
    def attachment_url(source, type = nil)
      asset_url(attachment_path(source, type))
    end
    
    def asset_url(name)
      self.context.asset_url(name)
    end
    
    def hires_url(source, type)
      hires_source = source.gsub(/(#{File.extname(source)})$/, '-hires\1')
      attachment_url(hires_source, type)
    end
  end
  
  class Tag < Liquid::Tag
    include LiquidExt
  end
  
  class Block < Liquid::Block
    include LiquidExt
  end
end

Dir[File.join(File.dirname(__FILE__), "tags", "*.rb")].each {|f| require f}
