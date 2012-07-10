module Alula
  class CDN
    def self.register(name, klass); cdns[name.to_s] = klass; end
    def self.cdns; @@cdns ||= {}; end
    def cdns; self.class.cdns; end
    
    def self.load(opts)
      site = opts[:site]
      
      # Check if we have environment related
      if site.config.cdn.has_key?("development") or site.config.cdn.has_key?("production")
        binding.pry
      else
        site.config.cdn.each do |cdn, opts|
          if cdns.has_key?(cdn)
            return cdns[cdn].new(opts, site: site)
          end
        end
      end
      
      raise "Cannot find CDN Provider(s): #{site.config.cdn.keys}"
    end
    
    attr_reader :site
    attr_reader :options
    
    def initialize(options, opts)
      @site = opts.delete(:site)
      @options = options
    end
  end
end

Dir[File.join(File.dirname(__FILE__), "cdns", "*.rb")].each {|f| require f}
