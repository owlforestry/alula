require 'alula/contents/post'
require 'alula/contents/page'
require 'alula/contents/attachment'

module Alula
  class Content
    attr_reader :site
    attr_reader :config
    
    attr_reader :pages
    attr_reader :posts
    attr_reader :attachments
    attr_reader :statics
    
    def initialize(opts = {})
      @site = opts.delete(:site)
      @config = @site.config
      
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
      
      # Write slugs to config
      self.config.slugs = (@posts + @pages).collect{|c| c.metadata.slug}
      self.config.slugs.count
    end
    
    def method_missing(meth, *args, &blk)
      if m = /^by_(\S+)$/.match(meth)
        return (self.pages + self.posts + self.attachments).find do |item|
          item.send(m[1]) == args.first
        end
      end
      
      super
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
      @site.config.content.generators.each do |type, options|
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
