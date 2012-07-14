require 'builder' # For Tilt

module Alula
  class Generator::Sitemap < Generator
    def generate
      urls_callback = ->(context) {
        (context.site.content.posts + context.site.content.pages)
          .reject {|content| content.generator == self }
          .collect { |content|
            content.languages.collect{|lang| {
              url: content.url(lang),
              lastmod: content.last_modified,
              priority: content.generator.nil? ? 0.5 : 0.3,
            }
          }
        }.flatten
      }
      
      self.site.content.pages << Alula::Content::Page.new({
        generator: self,
        urls: urls_callback,
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