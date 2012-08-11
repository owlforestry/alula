module Alula
  class BlockquoteTag < Block
    def render(context)
      quote = super
      
      tag = "<blockquote>"
      tag += quote
      if @options["author"] or @source
        tag += "<div class=\"source\">"
        tag += " &mdash; " if @options["author"] and @source.empty?
        tag += "<strong>#{@options["author"]}</strong>" if @options["author"]
        tag += " &mdash; " if @options["author"] and !@source.empty?
        tag += "<cite>#{@source}</cite>" if @source
        tag += "</div>"
      end
      tag += "</blockquote>"
    end
  end
end

Alula::Tag.register :blockquote, Alula::BlockquoteTag
