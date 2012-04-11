require 'yaml'
require 'tilt'
require 'liquid'
require 'kramdown'
require 'alula/engine/context'
require 'stringex'

module Alula
  class Engine
    class Content
      # Load out content type after defining our superclass
      require 'alula/engine/post'
      require 'alula/engine/page'
      
      attr_reader :engine, :config, :base, :name
      attr_accessor :data, :content, :output, :ext
      attr_accessor :date, :slug, :published, :categories, :title

      def initialize(engine, base, name)
        @engine = engine
        @config = @engine.config
        @base = base
        @name = name
        
        # Set post author by default to site author
        @data = { "author" => @engine.config.author }
        @data["layout"] = self.type ? self.type.to_s : "default"

        # Read file content
        read_content
        
        # Parse filename and filling missing information
        if self.type == :post
          begin
            /^(?<date>(?:\d+-\d+-\d+))-(?<slug>(?:.*))(?<ext>(?:\.[^.]+))$/ =~ name
            self.date ||= Time.parse(date)
            self.slug ||= slug
            self.ext ||= ext
          rescue ArgumentError
            raise "Post #{name} does not have a vlid date."
          end
        end
      end
      
      def <=>(other)
        cmp = self.date <=> other.date
        if 0 == cmp
          cmp = self.slug <=> other.slug
        end
        cmp
      end
      
      # Returns the view template for content
      def view
        @view ||= begin
          engine.find_view(@data["view"] || self.type.to_s)
        end
      end
      
      def render(context)
        begin
          self.content = Liquid::Template.parse(self.content).render(context.to_liquid)
        rescue => e
          puts "Liquid Exception: #{e.message} in #{self.name}"
        end
      end
      
      def id
        return @id if @id
        
        @id = self.data["id"] ? self.data["id"] : self.url.gsub(/[\/\.]/, ' ').to_url
      end
      
      def url
        return @url if @url
        
        url = if self.data['permalink']
          self.data['permalink']
        else
          {
            "year"  => self.date.strftime('%Y'),
            "month" => self.date.strftime('%m'),
            "day"   => self.date.strftime('%d'),
            "title" => CGI.escape(self.slug)
          }.inject(config.permalink) { |result, token|
            result.gsub(/:#{Regexp.escape token.first}/, token.last)
          }.gsub(/\/\//, '/')
        end
        @url = url
      end
      
      def destination
        path = File.join(config.public_path, CGI.unescape(url))
        path = File.join(path, "index.html") unless path[/\/$/].nil?
        path
      end
      
      def write
        path = destination
        FileUtils.mkdir_p(File.dirname(path))
        File.open(path, "w") { |io| io.write output }
      end
      
      def type
        case self.class.to_s
        when "Alula::Engine::Post"
          :post
        when "Alula::Engine::Page"
          :page
        end
      end
      
      # Navigation
      def next
        pos = self.engine.posts.index(self)
        if pos and pos < self.engine.posts.length - 1
          self.engine.posts[pos + 1]
        else
          nil
        end
      end
      
      def previous
        pos = self.engine.posts.index(self)
        if pos and pos > 0
          self.engine.posts[pos - 1]
        else
          nil
        end
      end
      
      private
      def read_content
        content = File.read(File.join(self.base, self.name))
        if /^(?<manifest>(?:---\s*\n.*?\n?)^(---\s*$\n?))(?<source>.*)/m =~ content
          self.content = parse_content(source)

          begin
            self.data.deep_merge!(YAML.load(manifest))
          rescue => e
            puts "YAML Exception reading #{name}: #{e.message}"
          end
          
          self.date = Time.parse(self.data["date"].to_s) if self.data.key?('date')
          self.slug = self.data['slug'] if self.data.key?('slug')
          self.categories = self.data['categories'] if self.data.key?('categories')
          self.title = self.data['title'] if self.data.key?('title')
        end
      end
      
      def parse_content(content)
        Kramdown::Document.new(content, {}).to_html
      end
    end
  end
end
