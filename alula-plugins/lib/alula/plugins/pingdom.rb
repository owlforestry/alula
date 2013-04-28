require 'alula/plugin'

module Alula
  class Pingdom
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins pingdom})
    end
    
    def self.version
      Alula::Plugins::VERSION::STRING
    end
    
    def self.install(options)
      # Require valid Pingdom token present in configuration
      return false unless options.token
      
      # Register addons
      Alula::Plugin.addon :head, ->(context) {
        "<script>var _prum=[['id','#{options.token}'],['mark','firstbyte',(new Date()).getTime()]];(function(){var s=document.getElementsByTagName('script')[0],p=document.createElement('script');p.async='async';p.src='//rum-static.pingdom.net/prum.min.js';s.parentNode.insertBefore(p,s);})();</script>"
      }
    end
  end
end

Alula::Plugin.register :pingdom, Alula::Pingdom
