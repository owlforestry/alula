module Alula
  class Engine
    class Page < Content
      def url
        return @url if @url
        
        path = File.dirname(@name)
        @url = File.join(path, File.basename(@name, File.extname(@name)) + ".html")
      end
    end
  end
end
