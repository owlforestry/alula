module Alula
  class Focused < Theme
    def self.install(options)
      Site.instance.config.attachments.image.thumbnail = "300x300"
      Site.instance.config.attachments.image.thumbnail_mode = :square
      
      true
    end
    
    def path
      File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. .. themes focused}))
    end
    
    def version
      Alula::Themes::VERSION
    end
  end
end

Alula::Theme.register :focused, Alula::Focused
