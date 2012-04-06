module Alula
  class Plugin
    def self.register(plugin, path)
      @@plugins ||= {}
      @@plugins[plugin] = path
    end
    
    def self.plugins
      @@plugins
    end
  end
end
