module Alula
  class Archive < Generator
    def generate
      # Loop all languages and count posts per language
      @languages = {}
      self.site.content.posts.each do |post|
        post.languages.each do |lang|
          @languages[lang] ||= []
          @languages[lang] << post
        end
      end
      
      titles = Hash[@languages.collect {|lang, x| [lang, I18n.t("archive.title", locale: lang)]}]
      
      archives = {}
      @languages.each do |lang, posts|
        options.templates.collect do |template|
          posts.collect do |post|
            archives[post.substitude(template, lang)] ||= {}
            key = "archive.title." + template.scan(/:(\w+)*/).flatten.join('-')
            archives[post.substitude(template, lang)][:title] ||= I18n.t(key, Hash[post.substitutes(lang).map{|k,v|[k.to_sym,v]}].merge(locale: lang))
            archives[post.substitude(template, lang)][:key] ||= key
            archives[post.substitude(template, lang)][:content] ||= {}
            archives[post.substitude(template, lang)][:content][lang] ||= []
            archives[post.substitude(template, lang)][:content][lang] << post
          end
        end
      end

      archives.each do |name, archive|
        self.site.content.pages << Alula::Content::Page.new({
          generator: self,
          posts: archive[:content],
          title: archive[:title],#titles.select {|lang, title| archive.keys.include?(lang)},
          name: name,
          slug: name,
          sidebar: false,
          template: "/:locale/:name/",
          site: self.site,
          view: "archive",
          key: archive[:key],
        },
        :previous => ->(hook, locale = nil) {
          pos = self.navigation(locale).index(self)
          if pos and pos < (self.navigation(locale).count - 1)
            self.navigation(locale)[pos + 1]
          else
            nil
          end
        },
        :next => ->(hook, locale = nil) {
          pos = self.navigation(locale).index(self)
          if pos and pos > 0
            self.navigation(locale)[pos - 1]
          else
            nil
          end
        },
        :navigation => ->(hook, locale = nil) {
          locale ||= self.current_locale || self.site.config.locale
          @navigation[locale] ||= self.site.content.pages.select { |item|
            item.metadata.generator == self.generator and item.metadata.key == self.metadata.key
          }
        }
        )
      end
    end
    
    def substitutes(locale, item)
      {
        "page" => item.metadata.pagenum.to_s,
      }
    end
  end
end

Alula::Generator.register :archive, Alula::Archive
