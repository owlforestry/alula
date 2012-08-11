module Alula
  module Helpers
    def addons(type)
      content = ""
      Alula::Plugin.addons[type].each do |addon|
        content += addon.respond_to?(:call) ? addon.call(self).to_s : addon
      end
      
      content
    end
  end
end