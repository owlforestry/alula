require 'alula/config'

module Alula
  class Site
    attr_reader :config
    
    def initialize(options)
      # Read local config
      @config = Config.new(options)
    end
  end
end
