module Alula
  class Engine
    class Page < Content
      def url
        return @url if @url
        
        if self.data.key?(:name)
          name = self.data[:name]
          unless name[/^\//]
            name = "/#{name}"
          end
          
          return name
        end
        
        path = File.dirname(self.name)
        extname = case File.extname(self.name)[1..-1]
        when "html"
        when "xml"
          File.extname(self.name)[1..-1]
        else
          "html"
        end
        # binding.pry if self.name[/feed/]
        @url = File.join(path, File.basename(self.name, File.extname(self.name)) + ".#{extname}").gsub(/\/\//, '/')
      end
      
      def posts
        self.data[:posts]
      end
      
      def next
        pos = self.engine.pages.index(self)
        if pos and pos < (self.engine.pages.length - 1)
          self.engine.pages[pos + 1]
        end
      end
      
      def previous
        if self.data[:page_num] > 0
          if self.data[:page_num] <= self.data[:total_pages]
            pos = self.engine.pages.index(self)
            if pos and pos > 0
              self.engine.pages[pos - 1]
            end
          end
        end
      end
    end
  end
end
