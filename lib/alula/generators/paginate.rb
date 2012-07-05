module Alula
  class Generator::Paginate < Generator
    def generate
      # Loop all languages and count posts per language
      @languages = {}
      self.site.content.posts.each do |post|
        post.languages.each do |lang|
          @languages[lang] ||= []
          @languages[lang] << post
        end
      end
      
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

        self.site.content.pages << Alula::Content::Page.new({
          generator: self,
          posts: posts,
          pagenum: (page + 1),
          pages: (pages + 1),
          title: Hash[languages.collect {|lang, x| [lang, "Page - #{page + 1}"]}],
          name: "page-#{(page + 1)}",
          slug: "page-#{(page + 1)}",
          template: self.options.template,
          site: self.site,
          view: self.options.view || "paginate",
        }, before_render: ->(item){ item.flush_render; item.metadata.embedded = true })
      end
    end
    
    def substitutes(locale, item)
      {
        "page" => item.metadata.pagenum.to_s,
      }
    end
    
    def generate_content
      # Generate pagination and pages
      num_posts = @site.content.posts.count
      pages = (num_posts / options.items).ceil
      
      (0..pages).each do |pagenum|
        pagename = "page#{pagenum}"
        
        @site.generated << Alula::Content::Page.new({
          site: @site,
          posts: @site.content.posts.slice(options.items * pagenum, options.items),
          current_page: (pagenum + 1),
          name: pagename,
        })
      end
    end
  end
end
