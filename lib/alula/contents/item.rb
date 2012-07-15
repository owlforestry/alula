require 'alula/contents/metadata'
require 'alula/core_ext'
require 'liquid'
require 'kramdown'
require 'stringex'
require 'shellwords'
require 'htmlentities'

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
      
      attr_accessor :navigation
      
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
        
        # Set up method overrides
        @hooks = hooks
        # hooks.each do |name, impl|
        #   self.class.send(:define_method, name, &impl)
        # end
        
        @url = {}
        @path = {}
        @ids = {}
        @navigation = {}
        @substitutes = {}
        @sidebar = {}
        
        # Initialize content variables
        flush
        
        # Initialize metadata
        @metadata = Metadata.new({
          # Defaults
          date: Time.new(0),
          pin: 500,       # Default sorting pin
          sidebar: true,  # Display item in sidebar (if page etc)
          layout: 'default',
          view: (self.class.to_s == "Alula::Content::Page" ? "page" : "post"),
          
          # Utilities
          base_locale: @site.config.locale,
          environment: @site.config.environment,
          
          last_modified: _last_modified,
          generator: nil,
        }.merge(opts))
        
        if /^((?<date>(?:\d+-\d+-\d+))-)?(?<slug>(?:.*))(?<extension>(?:\.[^.]+))$/ =~ @name
          @metadata.date = Time.parse(date) unless date.nil? rescue @metadata.date
          @metadata.slug = slug unless slug.nil?
          @metadata.extension = extension unless extension.nil?
        end
        
        # If payload requested, read it
        read_payload if has_payload?
      end
      
      # Functionality, existence
      def exists?
        @item.exists?
      end
      
      def extension
        @item.extension
      end
      
      def filepath
        @item.filepath
      end
      
      # Sorting
      def <=>(other)
        # Sort by date
        cmp = self.date <=> other.date

        # Sort by pinning, smaller marks higher in the list
        cmp == 0 and cmp = self.metadata.pin <=> other.metadata.pin
          
        # Sort by slug name alphabetically
        cmp == 0 and cmp = self.slug <=> other.slug

        cmp
      end
      
      # Renders actual content of itm using current layout
      # This handles all locales automatically
      def render(locale)
        @content[locale] ||= begin
          _old_locale = self.current_locale
          self.current_locale = locale
          
          # Flush if we have generator
          if @hooks[:render]
            instance_exec(locale, &@hooks[:render])
          end
          
          # Make sure our content is parsed
          parse_liquid(locale)
          parse_markdown(locale)
          
          self.view.render(item: self, content: self.body(locale), locale: locale)
        ensure
          self.current_locale = _old_locale
        end
      end
      
      def write
        # Write all languages
        languages = self.metadata.languages || [self.site.config.locale]
        
        languages.each do |locale|
          begin
            _old_locale = self.current_locale
            self.current_locale = locale

            # Render our content
            self.render(locale)
            
            output = self.layout.render(item: self, locale: locale) do
              self.content(locale)
            end
            
            # Filter output
            self.site.filters.each do |name, filter|
              output = filter.output(output, locale) if filter.respond_to?(:output)
            end
            
            # Write content to file
            @site.storage.output_public(self.path(locale)) do
              self.site.compressors.html.compress(output)
            end
          ensure
            self.current_locale = _old_locale
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
      def current_locale
        @@current_locale ||= nil
      end
      
      def current_locale=(newLocale)
        @@current_locale = newLocale
      end
      
      def content(locale = nil)
        @content[(locale || self.current_locale || self.site.config.locale)] ||= begin
          render(locale)
        end
      end
      
      def body(locale = nil)
        @body[(locale || self.current_locale || self.site.config.locale)] ||= begin
          parse_markdown(locale)
        end
      end
      
      def markdown(locale = nil)
        @markdown[(locale || self.current_locale || self.site.config.locale)] ||= begin
          parse_liquid(locale)
        end
      end
      
      def sidebar(locale = nil)
        locale ||= self.current_locale || self.site.config.locale
        @sidebar[locale] ||= begin
          items = self.site.config.content.sidebar.collect do |item|
            case item
            when :pages
              self.site.content.pages
                .select{|p| p.generator.nil? and p.languages.include?(locale) }
                .reject{|p| p.metadata.sidebar == false}
            when :languages
              # Get index page titles
              index_page = site.content.by_slug("index")
              index_page.languages
                .reject{|lang| lang == locale}
                .collect{|lang| Hashie::Mash.new({url: index_page.url(lang), title: I18n.t('language_name', locale: lang)}) }
            else
              @content.by_slug(self.config.index)
            end
          end
          items.flatten.select {|i| !i.nil?}
        end
      end
      
      def url(locale = nil)
        locale ||= self.current_locale || self.site.config.locale
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
        @ids[(locale || self.current_locale || self.site.config.locale)] ||= self.url(locale)
          .gsub(/\.\S+$/, '')
          .gsub(/[\/]/, ' ')
          .to_url
      end
      
      def path(locale = nil)
        locale ||= self.current_locale || self.site.config.locale
        @path[locale] ||= begin
          path = ::File.join(CGI.unescape(self.url(locale)))
          path = ::File.join(path, "index.html") unless path[/\/$/].nil?
          path
        end
      end
      
      def previous(locale = nil)
        if @hooks[:previous]
          instance_exec(locale, &@hooks[:previous])
        end
      end
      
      def next(locale = nil)
        if @hooks[:next]
          instance_exec(locale, &@hooks[:next])
        end
      end
      
      def navigation(locale = nil)
        if @hooks[:navigation]
          instance_exec(locale, &@hooks[:navigation])
        end
      end
      
      # 
      # Resets all cached variables and languages etc.
      def flush
        flush_render
        @markdown = {}
        @body = {}
      end
      
      def flush_render
        # Initialize current locale
        self.current_locale ||= nil
        @content = {}
      end
      
      # Proxy to metadata
      def method_missing(meth, *args, &blk)
        # Proxy to metadata
        if !meth[/=$/] and metadata.respond_to?(meth)
          # Invalidate some attributes depending on this
          if %w{template name slug}.include?(meth[0..-2])
            var = instance_variable_get("@#{meth[0..-2]}")
            instance_variable_set("@#{meth[0..2]}", var.class.new)
          end
          args.unshift(self.current_locale || @site.config.locale) if args.empty?
          metadata.send(meth, *args)
        else
          super
        end
      end
      
      # Substitues for URL
      def substitutes(locale = nil)
        locale ||=  self.current_locale || self.site.config.locale
        
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
      def _last_modified
        if @hooks[:last_modified]
          return instance_exec(locale, &@hooks[:next])
        end
        
        return unless self.class.to_s[/Page|Post/]
        mtime = nil
        unless @item.nil?
          mtime = @item.mtime
          if self.site.git
            rev = %x{git rev-list -n 1 HEAD #{Shellwords.escape(@item.filepath)}}.strip
            time = %x{git show --pretty=format:%ai --abbrev-commit #{rev}|head -1}.strip
            mtime = Time.parse(time) rescue nil
          end
        end
        mtime
      end
      
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
            _old_item = @site.context.item
            @site.context.locale = locale
            @site.context.item = self
            Liquid::Template.parse(@source).render(@site.context.to_liquid)
          ensure
            @site.context.locale = _old_locale
            @site.context.item = _old_item
          end
        end
      end
      
      def parse_markdown(locale)
        @body[locale] ||= begin
          coder = HTMLEntities.new
          quotes = %w{single.left single.right double.left double.right}.collect {|q|
            coder.encode(I18n.t("quotes.#{q}", locale: locale), :decimal).gsub(/&#(\d+);/, '\1')
          }
          
          body = Kramdown::Document.new(markdown(locale), {
            auto_ids: false,
            footnote_nr: 1,
            entity_output: 'as_char',
            html_to_native: true,
            toc_levels: '1..6',
            smart_quotes: quotes,
          }).to_html
          
          self.site.filters.each do |name, filter|
            body = filter.process(body, locale) if filter.respond_to?(:process)
          end
          
          body
        end
      end
    end
  end
end
