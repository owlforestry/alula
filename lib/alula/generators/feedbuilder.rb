module Alula
  class Generator::FeedBuilder < Generator
    def generate
      # Loop all languages and count posts per language
      @languages = {}
      self.site.content.posts.each do |post|
        post.languages.each do |lang|
          @languages[lang] ||= []
          @languages[lang] << post
        end
      end
      
      posts = Hash[
        @languages.collect do |lang, posts|
          [ lang, posts.slice(0, self.options.items) ]
        end
      ]
      
      self.site.content.pages << Alula::Content::Page.new({
        generator: self,
        posts: posts,
        title: Hash[@languages.collect {|lang, x| [lang, "Recent Posts"]}],
        name: "feed.xml",
        slug: "feed",
        template: self.options.template || "/:locale/:name",
        site: self.site,
        layout: "feed",
      })
    end
  end
end
