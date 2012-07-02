require 'alula/content/metadata'
require 'liquid'
require 'kramdown'

module Alula
  class Content
    class Item
      # Instance variables, internal
      # @source   :: raw source from file, liquid + markdown
      # @markdown :: parsed liquid, only markdown
      # @content  :: parsed markdown, raw content without layout
      attr_reader :metadata
      attr_reader :content
      
      attr_reader :name
      
      def self.has_payload
        class_variable_set(:@@payload, true)
      end
    
      def self.has_payload?
        class_variable_defined?(:@@payload) && class_variable_get(:@@payload)
      end
    
      def has_payload?
        self.class.has_payload?
      end
    
      def self.load(opts = {})
        # Return nothing if file is not regular file
        if (!File.file?(opts[:file]))
          return nil
        end
      
        # If payload is required by class and file doesn't contain it, just skip it
        if has_payload?
          if File.read(opts[:file], 3) != "---"
            return nil
          end
        end
      
        # All ok
        return self.new(opts)
      end
    
      def initialize(opts = {})
        @site = opts[:site]
        @file = opts[:file]
        @name = opts[:name] || File.basename(@file)
        
        @url = {}
        @path = {}
        
        # Initialize metadata
        @metadata = Metadata.new
        if /^(?<date>(?:\d+-\d+-\d+))-(?<slug>(?:.*))(?<extension>(?:\.[^.]+))$/ =~ @name
          @metadata.date = date
          @metadata.slug = slug
          @metadata.extension = extension
        end
        
        # If payload requested, read it
        read_payload if has_payload?
      end
      
      # Renders actual content item and saves it to disk
      def render
        # Parse content
        parse_liquid
        parse_markdown
        
        puts "--> Save #{name} to #{path("base")}"
      end
         
      # Accessors
      def url(locale = nil)
        @url[locale] ||= begin
          url = if @metadata.permalink
            @metadata.permalink
          else
            {
              "year"  => @metadata.date.strftime('%Y'),
              "month" => @metadata.date.strftime('%m'),
              "day"   => @metadata.date.strftime('%d'),
              "title" => CGI.escape(@metadata.slug)
            }.inject(@site.config.permalinks) { |result, token|
              result.gsub(/:#{Regexp.escape token.first}/, token.last)
            }.gsub(/\/\//, '/')
          end
          
          url
        end
      end
      
      def path(locale = nil)
        @path[locale] ||= begin
          path = File.join(@site.config.public_path, CGI.unescape(self.url(locale)))
          path = File.join(path, "index.html") unless path[/\/$/].nil?
          path
        end
      end
      
      private
      def read_payload
        # Do not read directly to instance variable as we know there is payload
        return if @file.nil?
        
        source = File.read(@file)
        if /^(?<manifest>(?:---\s*\n.*?\n?)^(---\s*$\n?))(?<source>.*)/m =~ source
          @source = source
          @metadata.load(manifest)
        end
      end
      
      def parse_liquid
        @markdown ||= begin
          Liquid::Template.parse(@source).render(@site.context.to_liquid)
        end
      end
      
      def parse_markdown
        @content ||= begin
          Kramdown::Document.new(@markdown, {
            auto_ids: true,
            footnote_nr: 1,
            entity_output: 'as_char',
            html_to_native: true,
            toc_levels: '1..6',
          }).to_html
        end
      end
    end
  end
end
