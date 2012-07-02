require 'alula/content/item'

module Alula
  class Content
    class Page < Item
      has_payload
      
      def url(locale)
        @url[locale] ||= @name
      end
    end
  end
end