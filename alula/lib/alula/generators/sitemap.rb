require 'builder' # For Tilt

module Alula
  class Sitemap < Generator
    def allow_compressing?
      return :normal
    end
    
    def generate
      urls_callback = ->(context) {
        (context.site.content.posts + context.site.content.pages)
          .reject {|content| content.generator == self }
          .reject {|content| content.metadata.sitemap == false }
          .collect { |content|
            content.languages.collect{|lang| {
              url: content.url(lang),
              lastmod: content.last_modified,
              priority: content.generator.nil? ? 0.5 : 0.3,
            }
          }
        }.flatten
      }
      
      @sitemap_page = Alula::Content::Page.new({
        generator: self,
        urls: urls_callback,
        title: "Sitemap",
        name: "sitemap.xml",
        slug: "sitemap",
        sidebar: false,
        template: self.options.template || "/:locale/:name",
        site: self.site,
        layout: "sitemap",
      })
      self.site.content.pages << @sitemap_page
    end
  end
end

Alula::Generator.register :sitemap, Alula::Sitemap