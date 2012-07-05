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
    
      def initialize(opts = {}, hooks = {})
        @site = opts.delete(:site)
        @item = opts.delete(:item)
        @name = opts.delete(:name) || @item.name
        
        @hooks = hooks
        
        @url = {}
        @path = {}
        @ids = {}
        @navigation = {}
        @substitutes = {}
        
        # Initialize content variables
        flush
        
        # Initialize metadata
        @metadata = Metadata.new({
          # Defaults
          date: Time.now,
          pin: 500, # Default sorting pin
          layout: 'default',
          view: (self.class.to_s == "Alula::Content::Page" ? "page" : "post"),
          
          # Utilities
          base_locale: @site.config.locale,
        }.merge(opts))
        
        if /^((?<date>(?:\d+-\d+-\d+))-)?(?<slug>(?:.*))(?<extension>(?:\.[^.]+))$/ =~ @name
          @metadata.date = date unless date.nil?
          @metadata.slug = slug unless slug.nil?
          @metadata.extension = extension unless extension.nil?
        end
        
        # If payload requested, read it
        read_payload if has_payload?
      end
      
      # Sorting
      def <=>(other)
        # Sort by date
        cmp = self.date <=> other.date
        if cmp == 0
          # Sort by pinning, smaller marks newer post
          cmp = other.metadata.pin <=> self.metadata.pin
          if cmp == 0
            # Sort by slug name alphabetically
            cmp = self.slug <=> other.slug
          end
        end
        cmp
      end
      
      # Renders actual content of itm using current layout
      # This handles all locales automatically
      def render(locale)
        @content[locale] ||= begin
          _old_locale = @@current_locale
          @@current_locale = locale
          
          # Make sure our content is parsed
          parse_liquid(locale)
          parse_markdown(locale)
        
          self.view.render(item: self, content: self.body(locale), locale: locale)
        ensure
          @@current_locale = _old_locale
        end
      end
      
      def write
        # Write all languages
        languages = self.metadata.languages || [self.site.config.locale]
        
        languages.each do |locale|
          begin
            _old_locale = @@current_locale
            @@current_locale = locale

            puts "--> outputting language #{locale} to #{path(locale)}"

            # if @hooks[:before_render]
            #   @hooks[:before_render].call(self)
            # end

            # Render our content
            self.render(locale)
                        
            output = self.layout.render(item: self, locale: locale) do
              self.content(locale)
            end
          
            # Write content to file
            @site.storage.output(self.path(locale)) do
              output
            end
          ensure
            @@current_locale = _old_locale
          end
        end
      end
         
      # Layout engine
      def layout
        @layout ||= @site.theme.layout(self.metadata.layout)
      end
      
      def view
        @view ||= @site.theme.view(self.metadata.view)
      end
      
      # Accessors
      def content(locale = nil)
        @content[(locale || @@current_locale || self.site.config.locale)]
      end
      
      def body(locale = nil)
        @body[(locale || @@current_locale || self.site.config.locale)]
      end
      
      def url(locale = nil)
        locale ||=  @@current_locale || self.site.config.locale
        @url[locale] ||= begin
          url = if @metadata.permalink(locale)
            @metadata.permalink(locale)
          else
            template = @metadata.template || (self.class.to_s == "Alula::Content::Page" ? @site.config.pagelinks : @site.config.permalinks)
            self.substitutes(locale).inject(template) { |result, token|
              result.gsub(/:#{Regexp.escape token.first}/, token.last)
            }.gsub(/\/\//, '/')
          end
          # Add .html only if we don't have extension already
          if ::File.extname(url).empty?
            url += ".html" unless url[/\/$/] and ::File.extname(url).empty?
          end
          url
        end
      end
      
      def id(locale = nil)
        @ids[(locale || @@current_locale || self.site.config.locale)] ||= self.url(locale).gsub(/[\/]/, ' ').to_url
      end
      
      def path(locale = nil)
        locale ||= @@current_locale || self.site.config.locale
        @path[locale] ||= begin
          path = ::File.join(CGI.unescape(self.url(locale)))
          path = ::File.join(path, "index.html") unless path[/\/$/].nil?
          path
        end
      end
      
      # Render time accessors
      def previous(locale = nil)
        locale ||= @@current_locale || @site.config.locale
        @navigation[locale] ||= self.site.content.posts.select { |item| item.languages.include?(locale) }
        
        pos = @navigation[locale].index(self)
        if pos and pos < (@navigation[locale].count - 1)
          @navigation[locale][pos + 1]
        else
          nil
        end
      end
      
      def next(locale = nil)
        locale ||= @@current_locale || @site.config.locale
        @navigation[locale] ||= self.site.content.posts.select { |item| item.languages.include?(locale) }
        
        pos = @navigation[locale].index(self)
        if pos and pos > 0
          @navigation[locale][pos - 1]
        else
          nil
        end
      end
      
      # Resets all cached variables and languages etc.
      def flush
        flush_render
        @markdown = {}
        @body = {}
      end
      
      def flush_render
        # Initialize current locale
        @@current_locale ||= nil
        @content = {}
      end
      
      # Proxy to metadata
      def method_missing(meth, *args, &blk)
        # Proxy to metadata
        if !meth[/=$/] and metadata.respond_to?(meth)
          args.unshift(@@current_locale || @site.config.locale) if args.empty?
          metadata.send(meth, *args)
        else
          super
        end
      end
      
      # Substitues for URL
      def substitutes(locale = nil)
        locale ||=  @@current_locale || self.site.config.locale
        
        @substitutes[locale] ||= begin
          subs = {
            "year"   => @metadata.date.strftime('%Y'),
            "month"  => @metadata.date.strftime('%m'),
            "day"    => @metadata.date.strftime('%d'),
            "locale" => (@site.config.locale == locale && @site.config.hides_base_locale ? "" : locale),
            "name"   => CGI.escape(name).gsub('%2F', '/'),
            "slug"   => CGI.escape(@metadata.slug(locale)).gsub('%2F', '/'),
            "title"  => @metadata.title(locale).to_url,
          }
          if self.metadata.generator
            subs.merge!(self.metadata.generator.substitutes(locale, self))
          end
          subs
        end
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
