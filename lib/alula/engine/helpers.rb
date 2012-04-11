require 'alula/engine/helpers/assets'

module Alula
  class Engine
    module Helpers
      def addons(placement)
        content = ""
        Plugins.addons(placement).each do |addon|
          content << case addon.class.to_s
          when "Proc"
            addon.call(self).to_s
          else
            addon
          end
        end
        
        content
      end
    end
  end
end
