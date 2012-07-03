require 'liquid'

module Alula
  module Plugins
    class LocaleTag < Liquid::Block
      def initialize(name, markup, tokens)
        super
        @lang = markup.strip
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
end

Liquid::Template.register_tag 'locale', Alula::Plugins::LocaleTag