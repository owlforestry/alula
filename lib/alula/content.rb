require 'alula/contents/post'
require 'alula/contents/page'
require 'alula/contents/attachment'

module Alula
  class Content
    attr_reader :pages
    attr_reader :posts
    attr_reader :attachments
    attr_reader :statics
    
    def initialize(opts = {})
      @site = opts.delete(:site)
      
      @pages = []
      @posts = []
      @attachments = []
      @statics = []
    end
    
    # Load our site content
    def load
      # Load everything we can have
      read_content(:posts, :pages, :attachments, :statics)
      
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
      @@lock = Mutex.new
      # Load all posts if requested
      if (types.include?(:posts))
        # Read posts
        @site.progress.create :load_posts, title: "Loading posts", total: @site.storage.posts.count
        @site.progress.display
        @site.storage.posts.each do |item|
          name, entry = item
          post = Post.load(item: entry, site: @site)
          @posts << post unless post.nil?
          @@lock.synchronize { @site.progress.step :load_posts }
        end
        # Sort
        @posts.sort!.reverse!
        @site.progress.finish :load_posts
      end
      
      # Load all pages if requested
      if (types.include?(:pages))
        @site.progress.create :load_pages, title: "Loading pages", total: @site.storage.pages.count
        @site.progress.display
        
        @site.storage.pages.each do |item|
          name, entry = item
          page = Page.load(item: entry, site: @site)
          @pages << page unless page.nil?
          
          @@lock.synchronize { @site.progress.step :load_pages }
        end
        @pages.sort!
        @site.progress.finish :load_pages
      end

      # Load all pages if requested
      if (types.include?(:attachments))
        @site.progress.create :load_attachments, title: "Loading attachments", total: @site.storage.attachments.count
        @site.progress.display
        
        @site.storage.attachments.each do |item|
          name, entry = item
          attachment = Attachment.load(item: entry, site: @site)
          @attachments << attachment unless attachment.nil?
          
          @@lock.synchronize { @site.progress.step :load_attachments }
        end
        
        @site.progress.finish :load_attachments
      end
      
      # Load all statics
      if (types.include?(:statics))
        @site.storage.statics.each do |name, entry|
          @statics << entry
        end
      end
    end
    
    def generate_content
      @site.config.generators.each do |type, options|
        
        generator = Alula::Generator.load(type: type, options: options, site: @site)
        if generator
          generator.generate
        end
      end
    end
  end
end
