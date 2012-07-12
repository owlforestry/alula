require 'builder' # For Tilt

module Alula
  class Generator::Sitemap < Generator
    def generate
      urls = (self.site.content.posts + self.site.content.pages).collect do |content|
        content.languages.collect{|lang| content.url(lang)}
      end

      self.site.content.pages << Alula::Content::Page.new({
        generator: self,
        urls: urls.flatten,
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