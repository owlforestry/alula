require 'alula/contents/item'

module Alula
  class Content
    class Post < Item
      has_payload
      
      def navigation(locale = nil)
        locale ||= self.current_locale || self.site.config.locale
        @navigation[locale] ||= self.site.content.posts.select { |item| item.languages.include?(locale) }        
      end
    end
  end
end