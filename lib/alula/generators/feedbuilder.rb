require 'builder' # As suggested by tilt

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
      titles = Hash[@languages.collect {|lang, x| [lang, I18n.t("feedbuilder.recent_posts", locale: lang)]}]
      posts = Hash[
        @languages.collect do |lang, posts|
          [ lang, posts.slice(0, self.options.items) ]
        end
      ]
      
      self.site.content.pages << Alula::Content::Page.new({
        generator: self,
        posts: posts,
        title: titles,
        name: "feed.xml",
        slug: "feed",
        template: self.options.template || "/:locale/:name",
        site: self.site,
        layout: "feed",
      },
      :previous => ->(locale) { nil },
      :next => ->(locale) { nil },
      :navigation => ->(locale) { nil },
      # :render => ->(locale) { self.posts.select{|post| post.metadata.view = "feed_post"; post.flush }}
      )
    end
  end
end
