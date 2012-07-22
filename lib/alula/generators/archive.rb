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
            archives[post.substitude(template, lang)][lang] ||= []
            archives[post.substitude(template, lang)][lang] << post
          end
        end
      end

      archives.each do |name, archive|
        self.site.content.pages << Alula::Content::Page.new({
          generator: self,
          posts: archive,
          title: titles.select {|lang, title| archive.keys.include?(lang)},
          name: name,
          slug: name,
          sidebar: false,
          template: "/:locale/:name/",
          site: self.site,
          view: "archive"
        })
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
