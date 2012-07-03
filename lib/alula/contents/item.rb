require 'alula/contents/metadata'
require 'liquid'
require 'alula/plugins/locale'
require 'kramdown'
require 'stringex'

module Alula
  class Content
    class Item
      # Instance variables, internal
      # @source   :: raw source from file, liquid + markdown
      # @markdown :: parsed liquid, only markdown
      # @body     :: parsed markdown, raw content without layout
      # @content  :: rendered content, using view, without layout
      
      # Metadata, contains all informative data for item
      attr_reader :metadata
      
      attr_reader :name
      attr_reader :site
      
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
        # Just return nil right away if we have no item
        return nil if opts[:item].nil?
        
        # Return nothing if file is not regular file
        return nil unless opts[:item].exists?

        # If payload is required by class and file doesn't contain it, just skip it
        return nil if has_payload? && !opts[:item].has_payload?
      
        # All ok
        return self.new(opts)
      end
    
      def initialize(opts = {})
        @site = opts.delete(:site)
        @item = opts.delete(:item)
        @name = @item.name
        # @name = opts[:name] || File.basename(@file)
        
        @url = {}
        @path = {}
        
        # Initialize content variables
        reset
        
        # Initialize metadata
        @metadata = Metadata.new({layout: 'default', view: (self.class.to_s == "Alula::Content::Page" ? "page" : "post")})
        
        if /^((?<date>(?:\d+-\d+-\d+))-)?(?<slug>(?:.*))(?<extension>(?:\.[^.]+))$/ =~ @name
          @metadata.date = date || Time.now
          @metadata.slug = slug
          @metadata.extension = extension
        end
        
        # If payload requested, read it
        read_payload if has_payload?
      end
      
      # Renders actual content of itm using current layout
      # This handles all locales automatically
      def render(locale)
        @content[locale] ||= begin
          # Make sure our content is parsed
          parse_liquid(locale)
          parse_markdown(locale)
        
          self.view.render(item: self, content: self.body(locale), locale: locale)
        end
      end
      
      def write
        # Write all languages
        languages = self.metadata.languages || [self.site.config.locale]
        
        languages.each do |locale|
          puts "--> outputting language #{locale} to #{path(locale)}"
          # Render our content
          self.render(locale)
          
          output = self.layout.render(item: self, locale: locale) do
            self.content(locale)
          end
          
          # Write content to file
          @site.storage.output(self.path(locale)) do
            output
          end
        end
      end
         
      # Accessors
      def layout
        @layout ||= @site.theme.layout(self.metadata.layout)
      end
      
      def view
        @view ||= @site.theme.view(self.metadata.view)
      end
      
      def content(locale = @site.config.locale)
        @content[locale]
      end
      
      def body(locale = @site.config.locale)
        @body[locale]
      end
      
      def url(locale = @site.config.locale)
        @url[locale] ||= begin
          url = if @metadata.permalink
            @metadata.permalink
          else
            template = self.class.to_s == "Alula::Content::Page" ? @site.config.pagelinks : @site.config.permalinks
            
            {
              "year"   => @metadata.date.strftime('%Y'),
              "month"  => @metadata.date.strftime('%m'),
              "day"    => @metadata.date.strftime('%d'),
              "locale" => (@site.config.locale == locale && @site.config.hides_base_locale ? "" : locale),
              "slug"   => CGI.escape(@metadata.slug(locale)).gsub('%2F', '/'),
              "title"  => @metadata.title(locale).to_url,
            }.inject(template) { |result, token|
              result.gsub(/:#{Regexp.escape token.first}/, token.last)
            }.gsub(/\/\//, '/')
          end
          url += ".html" unless url[/\/$/]
          url
        end
      end
      
      def path(locale = @site.config.locale)
        @path[locale] ||= begin
          path = ::File.join(CGI.unescape(self.url(locale)))
          path = ::File.join(path, "index.html") unless path[/\/$/].nil?
          path
        end
      end
      
      # Resets all cached variables and languages etc.
      def reset
        @markdown = {}
        @body = {}
        @content = {}
      end
      
      private
      def read_payload
        # Do not read directly to instance variable as we know there is payload
        return if @item.nil?
        
        # source = File.read(@file)
        source = @item.read
        if /^(?<manifest>(?:---\s*\n.*?\n?)^(---\s*$\n?))(?<source>.*)/m =~ source
          @source = source
          @metadata.load(manifest)
        end
      end
      
      def parse_liquid(locale)
        @markdown[locale] ||= begin
          begin
            _old_locale = @site.context.locale
            @site.context.locale = locale
            Liquid::Template.parse(@source).render(@site.context.to_liquid)
          ensure
            @site.context.locale = _old_locale
          end
        end
      end
      
      def parse_markdown(locale)
        @body[locale] ||= begin
          Kramdown::Document.new(@markdown[locale], {
            auto_ids: false,
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
