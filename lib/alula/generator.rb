module Alula
  class Generator
    autoload :Paginate, 'alula/generators/paginate'
    autoload :FeedBuilder, 'alula/generators/feedbuilder'
    autoload :Sitemap, 'alula/generators/sitemap'
    
    attr_reader :options
    attr_reader :site
    
    def self.load(opts)
      type = opts.delete(:type)
      options = opts.delete(:options)
      
      # Try to find our generator
      cls_name = self.constants.select {|t| t.to_s.downcase == type.downcase}.first
      if cls_name
        cls = self.const_get(cls_name)
        gen = cls.new(options, opts)
      end
    end
    
    def initialize(options, opts)
      @options = options
      @site = opts.delete(:site)
    end
    
    def substitutes(locale, item)
      {}
    end
  end
end
