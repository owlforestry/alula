module Alula
  class Filter
    def self.register(name, klass); filters[name.to_s] = klass; end
    def self.filters; @@filters ||= {}; end
    def filters; self.class.filters; end
    
    def self.load(name, options)
      if filters[name]
        filter = filters[name].new(options)
        return filter
      end
    end
    
    def initialize(options)
      @options = options
    end
  end
end

Dir[File.join(File.dirname(__FILE__), "filters", "*.rb")].each {|f| require f}
