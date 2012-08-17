module Alula
  class Generator
    # autoload :Paginate, 'alula/generators/paginate'
    # autoload :FeedBuilder, 'alula/generators/feedbuilder'
    # autoload :Sitemap, 'alula/generators/sitemap'
    def self.register(name, klass); generators[name.to_s] = klass; end
    def self.generators; @@generators ||= {}; end
    def generators; self.class.generators; end
    
    attr_reader :options
    attr_reader :site
    
    def self.load(opts)
      name = opts.delete(:type).to_s
      options = opts.delete(:options)
      
      # Try to find our generator
      # cls_name = self.constants.select {|t| t.to_s.downcase == type.downcase}.first
      # if cls_name
        # cls = self.const_get(cls_name)
        # gen = cls.new(options, opts)
      # end
      if generators[name] and !(!!options == options and !options)
        generator = generators[name]
        return generator.new(options, opts)
      end
    end
    
    def initialize(options, opts)
      @options = options
      @site = opts.delete(:site)
    end
    
    def substitutes(locale, item)
      {}
    end
    
    def allow_compressing?
      :high
    end
    
    protected
    def fetch_languages
      languages = {}
      self.site.content.posts.each do |post|
        post.languages.each do |lang|
          languages[lang] ||= []
          languages[lang] << post
        end
      end
      languages
    end
    
  end
end

# Load all generators
Dir[File.join(File.dirname(__FILE__), "generators", "*.rb")].each {|f| require f}
