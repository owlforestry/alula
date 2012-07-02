module Alula
  class Generator
    class Paginate < Generator
      def generate_content
        # Generate pagination and pages
        num_posts = @site.content.posts.count
        pages = (num_posts / options.items).ceil
        
        (0..pages).each do |pagenum|
          pagename = "page#{pagenum}"
          
          @site.generated << Alula::Content::Page.new({
            site: @site,
            config: @config,
            posts: @site.content.posts.slice(options.items * pagenum, options.items),
            current_page: (pagenum + 1),
            name: pagename,
          })
        end
      end
    end
  end
end
