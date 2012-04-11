require 'alula/engine/plugins/tag'
require 'alula/engine/plugins/assets'

module Alula
  class Engine
    class Plugins
      def self.addon(placement, content)
        @@addons ||= Hash.new {|hash, key| hash[key] = [] }
        @@addons[placement] << content
      end
      
      def self.addons(placement)
        @@addons ||= Hash.new {|hash, key| hash[key] = [] }
        @@addons[placement]
      end
    end
  end
end
