require 'alula/content/item'

module Alula
  class Content
    class Post < Item
      has_payload
    end
  end
end