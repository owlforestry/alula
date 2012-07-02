require 'alula/generator/paginate'
require 'alula/generator/categories'

module Alula
  class Generator
    attr_reader :options
    
    def initialize(options = {}, opts)
      @options = options
      @site = opts[:site]
      @config = opts[:config]
    end
    
    def generate_content
    end
  end
end
