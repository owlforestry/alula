require 'builder' # For Tilt

module Alula
  class Generator::Sitemap < Generator
    def generate
      self.site.content.pages << Alula::Content::Page.new({
        generator: self,
        urls: ->(context) {
          (context.site.content.posts + context.site.content.pages).collect { |content|
            content.languages.collect{|lang| {url: content.url(lang), lastmod: content.last_modified } }
          }.flatten
          },
        title: "Sitemap",
        name: "sitemap.xml",
        slug: "sitemap",
        template: self.options.template || "/:locale/:name",
        site: self.site,
        layout: "sitemap",
      })
    end
  end
end