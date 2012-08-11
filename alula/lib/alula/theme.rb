require 'alula/theme/layout'

module Alula
  class Theme
    def self.register(name, klass); themes[name.to_s] = klass; end
    def self.themes; @@themes ||= {}; end
    def themes; self.class.themes; end
    
    def self.load(name, options)
      if themes[name] and !(!!options == options and !options)
        theme = themes[name]
        return theme.new(options) if theme.install(options)
      end
    end
    
    def self.install(options); true; end
    
    attr_reader :version
    attr_reader :site
    attr_reader :theme
    attr_reader :path
    attr_reader :layouts
    attr_reader :context
    
    # def self.register(theme, path, version)
    #   @@themes ||= {}
    #   @@themes[theme.to_s] = ::File.join(path, theme.to_s)
    #   
    #   @@theme_versions ||= {}
    #   @@theme_versions[theme.to_s] = version
    # end
    
    # def self.load(opts)
    #   return nil unless self.class_variable_defined?(:@@themes)
    #   site = opts[:site]
    #   
    #   theme_name = site.config.theme
    #   return self.new(theme_name, opts) if @@themes.has_key?(theme_name)
    # 
    #   return nil
    # end
    # 
    def initialize(opts)
      @site = Site.instance
      # @theme = theme
      # @path = @@themes[theme]
      
      @context = @site.context
      
      @layouts = {}
      @views = {}
      
      # @version = @@theme_versions[theme]
    end
    
    def name
      themes.key(self.class)
    end
    
    def searchpath(type, name)
      [
        # Blog custom
        ::File.join(self.site.storage.path(:custom), type, "#{name}.*"),
        
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
          { :format => :html5, :ugly => @site.config.assets.compress }
        else
          {}
        end
    end
  end
end
