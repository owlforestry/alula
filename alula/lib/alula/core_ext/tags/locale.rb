module Alula
  class LocaleTag < Block
    def prepare
      @lang = @markup.strip
    end
    
    def render(context)
      if @lang == context.locale
        super
      else
        ''
      end
    end
  end
end

Alula::Tag.register :locale, Alula::LocaleTag
