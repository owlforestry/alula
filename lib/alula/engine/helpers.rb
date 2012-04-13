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
      
      #=link_to "&laquo; #{page.previous.title}", page.previous.url, :class => "left", :title => "Previous Post: #{page.previous.title}"
      def link_to(content, url, attributes = {})
        tag = "<a"
        tag += " href=\"#{url}\""
        attributes.each do |name, value|
          tag += " #{name}=\"#{value}\""
        end
        tag += ">#{content}</a>"
      end
      
      def include(layout, obj)
        old_page = self.page
        begin
          layout = engine.find_layout("_#{layout.to_s}")
          self.page = obj
          layout.render self
        ensure
          self.page = old_page
        end
      end
    end
  end
end
