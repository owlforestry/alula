module Alula
  class Engine
    class Page < Content
      def url
        return @url if @url
        
        @url = File.basename(@name, File.extname(@name)) + ".html"
      end
    end
  end
end
