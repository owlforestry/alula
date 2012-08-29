module Alula
  class Plugin
    def self.register(name, klass)
      plugins[name.to_s] = klass
    end
    
    def self.plugins
      @@plugins ||= {}
    end
    
    def plugins
      self.class.plugins
    end
    
    def self.load(name, options)
      if plugins[name] and !(!!options == options and !options)
        plugin = plugins[name]
        return plugin if plugin.install(options || Hashie::Mash.new)
      end
    end
    
    def self.addons
      @@addons ||= Hash.new {|hash, key| hash[key] = []}
    end
    
    def self.addon(type, content_or_block)
      addons[type] << content_or_block
    end
    
    def self.prepend_addon(type, content_or_block)
      addons[type].unshift content_or_block
    end
    
    def self.script(placement, content_or_block)
      name = caller_name
      
      if self.cookieconsent?(name)
        self.cookieconsented(name)
      end
      
      script = <<-EOS
      <script type="#{self.cookieconsent?(name) ? "text/plain" : "text/javascript"}" #{self.cookieconsent?(name) ? "class=\"cc-onconsent-#{@@cookieconsent[name].to_s}\"" : ""}>
      EOS
      if content_or_block.kind_of?(Proc)
        scpt = ->(context) { script + content_or_block.call(context) + "</script>" }
      else
        scpt = script + content_or_block + "</script>"
      end

      self.addon(placement, scpt)
    end
    
    def self.needs_cookieconsent(type = 'analytics')
      name = caller_name
      
      @@cookieconsent ||= {}
      @@cookieconsent[name] = type
    end
    
    def self.cookieconsent?(name = nil)
      if name.nil?
        @@cookieconsent.kind_of?(Hash)
      else
        @@cookieconsent.kind_of?(Hash) and @@cookieconsent.key?(name)
      end
    end
    
    def self.cookieconsented(name)
      @@cookieconsented ||= {}
      @@cookieconsented[name] = true
    end
    
    def self.cookieconsent_types
      @@cookieconsented ||= {}
      if @@cookieconsented.kind_of?(Hash)
        @@cookieconsented.keys
      else
        []
      end
    end
    
    def self.script_load_mode=(mode)
      @@script_load_mode = case mode
      when :sync
        :sync
      when :defer
        self.script_load_mode == :sync ? :sync : :defer
      end
    end
    
    def self.script_load_mode
      @@script_load_mode ||= :async
    end
    
    private
    def self.caller_name
      caller[1].gsub(/.*\/(.*)\.\w+:\d+.*/, '\1').downcase
    end
  end
end
