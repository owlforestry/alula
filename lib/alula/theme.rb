require 'alula/theme/layout'

module Alula
  class Theme
    attr_reader :site
    attr_reader :theme
    attr_reader :path
    attr_reader :layouts
    attr_reader :context
    
    def self.register(theme, path)
      @@themes ||= {}
      @@themes[theme.to_s] = ::File.join(path, theme.to_s)
    end
    
    def self.load(opts)
      return nil unless self.class_variable_defined?(:@@themes)
      site = opts[:site]
      
      theme_name = site.config.theme
      return self.new(theme_name, opts) if @@themes.has_key?(theme_name)

      return nil
    end
    
    def initialize(theme, opts)
      @site = opts.delete(:site)
      @theme = theme
      @path = @@themes[theme]
      
      @context = @site.context
      
      @layouts = {}
      @views = {}
    end
    
    def layout(name)
      @layouts[name] ||= begin
        # Find our layout name
        file = Dir[::File.join(self.path, "layouts", "#{name}.*")].first
        if file
          Layout.new(theme: self, name: name, file: file)
        end
      end
    end
    
    def view(name)
      @views[name] ||= begin
        # Find our layout name
        file = Dir[::File.join(self.path, "views", "#{name}.*")].first
        if file
          View.new(theme: self, name: name, file: file)
        end
      end
    end
  end
end
