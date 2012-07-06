require 'alula/contents/item'

module Alula
  class Content
    class Post < Item
      has_payload
      
      def previous(locale = nil)
        pos = self.navigation(locale).index(self)
        if pos and pos < (self.navigation(locale).count - 1)
          self.navigation(locale)[pos + 1]
        else
          nil
        end
      end
      
      def next(locale = nil)
        pos = self.navigation(locale).index(self)
        if pos and pos > 0
          self.navigation(locale)[pos - 1]
        else
          nil
        end
      end
      
      def navigation(locale = nil)
        locale ||= self.current_locale || self.site.config.locale
        @navigation[locale] ||= self.site.content.posts.select { |item| item.languages.include?(locale) }        
      end
    end
  end
end