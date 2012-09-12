module Alula
  class Bootstrap < Theme
    def path
      File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. .. themes bootstrap}))
    end
    
    def version
      Alula::Themes::VERSION::STRING
    end
  end
end

Alula::Theme.register :bootstrap, Alula::Bootstrap
