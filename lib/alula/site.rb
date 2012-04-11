require 'alula/engine'

module Alula
  class Site
    attr_reader :config
    
    def initialize(override = {})
      @engine = Alula::Engine.new
      @config = @engine.config
      
      # Disable verbose
      @config.verbose = false unless override[:verbose]
    end
    
    def generate
      @engine.generate
    end
    
    def preview
      @engine.generate if config.generate
      
      require 'webrick'
        FileUtils.mkdir_p("public")

        mime_types = WEBrick::HTTPUtils::DefaultMimeTypes
        mime_types.store 'js', 'application/javascript'

        s = WEBrick::HTTPServer.new(
          :Port            => config.port,
          :MimeTypes       => mime_types
        )
        s.mount('/', WEBrick::HTTPServlet::FileHandler, "public")
        t = Thread.new {
          s.start
        }

        trap("INT") { s.shutdown }
        t.join()
    end
    
    # def asset_attach(a_post, assets)
    #   # Find the post
    #   post = find_post(a_post) or raise "Cannot find post #{a_post}"
    #   
    #   /(?<date>(\d{4}-\d{2}-\d{2}))/ =~ post
    #   date = Time.parse(date)
    #   asset_path = File.join(%w{%Y %m %d}.collect{|f| date.strftime(f) })
    #   
    #   helper = Alula::AssetManager.new(asset_path, @config)
    #   
    #   post_io = File.open(post, "a")
    #   assets.each do |asset|
    #     type, asset_name = helper.process(asset)
    #     if asset_name
    #       # Asset processed
    #       puts "(#{asset_name}) done."
    #       if handler = Alula::Plugins.attachment_handler(type)
    #         post_io.puts handler.call(asset_name)
    #       else
    #         case type
    #         when :image
    #           post_io.puts "{% image _images/#{asset_name} %}"
    #         when :movie
    #           post_io.puts "{% video #{asset_name} %}"
    #         else
    #           post_io.puts "{% comment %}Unknown asset type #{type}{% endcomment %}"
    #         end
    #       end
    #     else
    #       puts "(#{asset}) cannot process."
    #     end
    #   end
    # end
    
    private
    # def find_post(post)
    #   if File.exists?(post)
    #     return post
    #   elsif File.exists?(File.join("posts", post))
    #     return File.join("posts", post)
    #   else
    #     # Try to find by title
    #     title = post.to_url
    #     posts = Dir[File.join("posts", "*")].select { |p| p =~ /#{title}/ }
    #     if posts.count == 1
    #       return posts.first
    #     end
    #   end
    # end

  end
end
