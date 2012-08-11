require 'sprockets'

module Alula
  class Environment < Sprockets::Environment
    def initialize
      super
      
      @used = []
    end
    
    def used
      @used.uniq
    end
    
    def [](key)
      @used << key
      super
    end
  end
end
