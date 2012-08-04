module Alula
  class Minimal < Theme
    def path
      File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. .. themes minimal}))
    end
    
    def version
      Alula::Themes::VERSION
    end
  end
end

Alula::Theme.register :minimal, Alula::Minimal
