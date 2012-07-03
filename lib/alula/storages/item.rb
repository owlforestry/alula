module Alula
  class Storage::Item
    attr_reader :name
    
    def initialize(opts = {})
      @name = opts.delete(:name)
      @site = opts.delete(:site)
    end
  end
end