require 'hashie/mash'

module Alula
  class Plugin
    def self.register(name, klass); plugins[name.to_s] = klass; end
    def self.plugins; @@plugins ||= {}; end
    def plugins; self.class.plugins; end
    
    def self.load(name, options)
      if plugins[name]
        plugin = plugins[name]
        return plugin if plugin.install(options || Hashie::Mash.new)
      end
    end
    
    def self.addons; @@addons ||= Hash.new {|hash, key| hash[key] = []}; end
    def self.addon(type, content_or_block); addons[type] << content_or_block; end
  end
end
