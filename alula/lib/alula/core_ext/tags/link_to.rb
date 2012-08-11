module Alula
  class LinkToTag < Tag
    def content
      target = if @options["href"]
        @options["href"]
      elsif @options["slug"]
        item = @context.site.content.by_slug(@options["slug"])
        item.nil? ? "" : item.url
      end
      @context.link_to(@options["source"], target)
    end
  end
end

Alula::Tag.register :link_to, Alula::LinkToTag
