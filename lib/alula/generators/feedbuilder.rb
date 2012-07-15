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
      
      @feed_page = Alula::Content::Page.new({
        generator: self,
        posts: posts,
        title: titles,
        name: "feed.xml",
        slug: "feed",
        sidebar: false,
        template: self.options.template || "/:locale/:name",
        site: self.site,
        layout: "feed",
      },
      :previous => ->(locale) { nil },
      :next => ->(locale) { nil },
      :navigation => ->(locale) { nil },
      )
      self.site.content.pages << @feed_page
      
      # Add link to head
      Alula::Plugin.addon(:head, ->(context) {
        "<link rel=\"alternate\" type=\"application/rss+xml\" title=\"RSS\" href=\"#{context.url_for(@feed_page.url(context.locale))}\">"
      })
      # -# %link{rel: "alternate", type: "application/rss+xml", title: "RSS", href: "/feed.xml"}
    end
  end
end
