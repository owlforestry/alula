require 'alula/contents/post'
require 'alula/contents/page'
require 'alula/contents/attachment'

module Alula
  class Content
    attr_reader :pages
    attr_reader :posts
    attr_reader :attachments
    attr_reader :generated
    
    def initialize(opts = {})
      @site = opts.delete(:site)
      
      @pages = []
      @posts = []
      @attachments = []
    end
    
    # Load our site content
    def load
      # Load everything we can have
      read_content(:posts, :pages, :attachments)
      
      # Generate our dynamic content (pages, categories, archives, etc. etc.)
      generate_content
    end
    
    def by_name(name)
      (self.pages + self.posts + self.attachments).each do |item|
        return item if item.name == name
      end
      nil
    end
    
    def by_slug(slug)
      (self.pages + self.posts + self.attachments).each do |item|
        return item if item.slug == slug
      end
      nil
    end
    
    private
    def read_content(*types)
      # Load all posts if requested
      if (types.include?(:posts))
        # Read posts
        @site.storage.posts.each do |name, entry|
          post = Post.load(item: entry, site: @site)
          @posts << post unless post.nil?
        end
        # Sort
        @posts.sort!.reverse!
      end
      
      # Load all pages if requested
      if (types.include?(:pages))
        @site.storage.pages.each do |name, entry|
          page = Page.load(item: entry, site: @site)
          @pages << page unless page.nil?
        end
        @pages.sort!
      end

      # Load all pages if requested
      if (types.include?(:attachments))
        @site.storage.attachments.each do |name, entry|
          attachment = Attachment.load(item: entry, site: @site)
          @attachments << attachment unless attachment.nil?
        end
      end

    end
    
    def generate_content
      @site.config.generators.each do |type, options|
        
        generator = Alula::Generator.load(type: type, options: OpenStruct.new(options), site: @site)
        if generator
          generator.generate
        end
      end
    end
  end
end
