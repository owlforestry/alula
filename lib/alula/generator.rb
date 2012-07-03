module Alula
  class Generator
    attr_reader :options
    
    # Lazy=load generators
    autoload :Paginate, 'alula/generators/paginate'
    autoload :Categories, 'alula/generators/categories'
    
    def initialize(options = {}, opts)
      @options = options
      @site = opts[:site]
      @config = opts[:config]
    end
    
    def generate_content
    end
  end
end
