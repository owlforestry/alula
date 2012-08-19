module Alula
  class Paginate < Generator
    def generate
      # Loop all languages and count posts per language
      @languages = fetch_languages
      # @languages = {}
      # self.site.content.posts.each do |post|
      #   post.languages.each do |lang|
      #     @languages[lang] ||= []
      #     @languages[lang] << post
      #   end
      # end
      
      # Maximum amount of posts
      num_posts = self.site.content.posts.count
      # Maximum number of required pages
      pages = (num_posts / self.options.items).ceil
      
      (0..pages).each do |page|
        languages = @languages.select { |lang, posts| posts.count > page * self.options.items }
        posts = Hash[
          languages.collect do |lang, posts|
            [ lang, posts.slice(page * self.options.items, self.options.items) ]
          end
        ]
        titles = Hash[languages.collect {|lang, x| [lang, I18n.t("paginate.title", locale: lang, page: (page + 1))]}]
        descriptions = Hash[languages.collect {|lang, x| [lang, I18n.t("paginate.description", locale: lang, page: (page + 1))]}]

        self.site.content.pages << Alula::Content::Page.new({
          generator: self,
          posts: posts,
          pagenum: (page + 1),
          pages: (pages + 1),
          title: titles,
          description: descriptions,
          name: "page-#{(page + 1)}",
          slug: "page-#{(page + 1)}",
          sidebar: false,
          template: self.options.template,
          site: self.site,
          view: self.options.view || "paginate",
        },
        :navigation => ->(hook, locale = nil) {
          locale ||= self.current_locale || self.site.config.locale
          @navigation[locale] ||= self.site.content.pages.select { |item| item.metadata.generator == self.generator and item.languages.include?(locale) }
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

Alula::Generator.register :paginate, Alula::Paginate
