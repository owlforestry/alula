require 'tilt/jbuilder'
# Rabl.register!

module Alula
  class FeedJSON < Generator
    def allow_compressing?
      :normal
    end
    
    def generate
      # Loop all languages and count posts per language
      @languages = {}
      (self.site.content.posts + self.site.content.pages).each do |post|
        post.languages.each do |lang|
          @languages[lang] ||= []
          @languages[lang] << post
        end
      end
      titles = Hash[@languages.collect {|lang, x| [lang, I18n.t("feedjson.recent_posts", locale: lang)]}]
      posts = Hash[
        @languages.collect do |lang, posts|
          [ lang, posts.slice(0, self.options.items) ]
        end
      ]
      
      @feedjson = Alula::Content::Page.new({
        generator: self,
        posts: posts,
        title: titles,
        name: self.options.name,
        slug: self.options.slug,
        sidebar: false,
        template: self.options.template,
        site: self.site,
        layout: "feed.json",
      },
      :previous => ->(hook, locale = nil) { nil },
      :next => ->(hook, locale = nil) { nil },
      :navigation => ->(hook, locale = nil) { nil },
      :write => ->(hook, locale = nil) {
        begin
          _old_renderer = self.posts.collect{|p| p.metadata.renderer}
          self.posts.cycle(1) { |p| p.flush; p.metadata.renderer = self.generator;}
          hook.call
        ensure
          self.posts.cycle(1) {|p| p.metadata.renderer = _old_renderer.shift }
        end
      },
      )
      self.site.content.pages << @feedjson
      
      # Add link to head
      Alula::Plugin.addon(:head, ->(context) {
        "<link rel=\"alternate\" type=\"application/json\" title=\"FeedJSON\" href=\"#{context.url_for(@feedjson.url(context.locale))}\">"
      })
    end
  end
end

Alula::Generator.register :feedjson, Alula::FeedJSON
