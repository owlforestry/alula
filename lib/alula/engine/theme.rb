module Alula
  class Engine
    class Theme
      def self.find(theme_name)
        if @@themes.key?(theme_name)
          @@themes[theme_name][:dir]
        else
          raise "Cannot find theme #{theme_name}"
        end
      end
      
      def self.register(name, dir)
        @@themes ||= {}
        @@themes[name] = {:dir => dir}
      end
    end
  end
end
