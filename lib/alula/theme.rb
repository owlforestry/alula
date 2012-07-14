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
    
    def searchpath(type, name)
      [
        # Theme path
        ::File.join(self.path, type, "#{name}.*"),
        
        # Alula vendor path
        ::File.join(::File.dirname(__FILE__), "..", "..", "vendor", type, "#{name}.*")
      ]
    end
    
    def layout(name)
      @layouts[name] ||= begin
        # Find our layout name
        file = Dir[*self.searchpath("layouts", name)].first
        if file
          Layout.new(theme: self, name: name, file: file)
        else
          raise "Cannot find layout #{name}"
        end
      end
    end
    
    def view(name)
      @views[name] ||= begin
        # Find our layout name
        # file = Dir[::File.join(self.path, "views", "#{name}.*")].first
        file = Dir[*self.searchpath("views", name)].first
        if file
          View.new(theme: self, name: name, file: file)
        else
          raise "Cannot find view #{name}"
        end
      end
    end
    
    def options(file)
      options = case File.extname(file)[1..-1]
        when "haml"
          { :format => :html5 }
        else
          {}
        end
    end
  end
end
