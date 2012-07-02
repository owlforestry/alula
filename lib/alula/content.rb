require 'alula/content/post'
require 'alula/content/page'
require 'alula/content/attachement'

module Alula
  class Content
    attr_reader :pages
    attr_reader :posts
    attr_reader :attachements
    
    def initialize(opts = {})
      @site = opts[:site]
      @config = opts[:config]
      
      @pages = []
      @posts = []
      @attachements = []
    end
    
    # Load our site content
    def load
      # Load everything we can have
      read_content(:posts, :pages, :attachements)
    end
    
    private
    def read_content(*types)
      # Load all posts if requested
      if (types.include?(:posts))
        # Read posts
        Dir[File.join(@config.posts_path, "**", "*")].each do |entry|
          post = Post.load(site: @site, file: entry)
          if (post)
            @posts << post
          end
        end
      end
      
      # Load all pages if requested
      if (types.include?(:pages))
        Dir[File.join(@config.pages_path, "**", "*")].each do |entry|
          page = Page.load(site: @site, file: entry)
          if (page)
            @pages << page
          end
        end
      end

      # Load all pages if requested
      if (types.include?(:attachements))
        Dir[File.join(@config.attachements_path, "**", "*")].each do |entry|
          attachement = Attachement.load(site: @site, file: entry)
          if (attachement)
            @attachements << attachement
          end
        end
      end

    end
  end
end
