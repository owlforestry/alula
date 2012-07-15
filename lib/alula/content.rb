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
      # Load all posts if requested
      if (types.include?(:posts))
        @posts = _read_content_type(Post, @site.storage.posts, "Loading Posts")
        @posts.sort!.reverse!
      end
      
      # Load all pages if requested
      if (types.include?(:pages))
        @pages = _read_content_type(Page, @site.storage.pages, "Loading Pages")
        @pages.sort!
      end

      # Load all attachments if requested
      if (types.include?(:attachments))
        @attachments = _read_content_type(Attachment, @site.storage.attachments, "Loading Attachments")
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

    def _read_content_type(type, items, title)
      @@lock ||= Mutex.new
      
      @collection = []
      
      @site.progress.create "load_#{type.to_s}", title: title, total: items.count
      @site.progress.display
      
      items.each do |item|
        name, entry = item
        itm = type.load(item: entry, site: @site)
        @collection << itm unless itm.nil?
        @@lock.synchronize { @site.progress.step "load_#{type.to_s}" }
      end

      # Sort
      @site.progress.finish "load_#{type.to_s}"
      
      @collection
    end
  end
end
