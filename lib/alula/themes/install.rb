require 'alula/theme'

module Alula
  class Themes
    def self.install_themes
      themedir = File.expand_path(File.join(File.dirname(__FILE__), *%w{.. .. .. themes}))
      Alula::Theme.register(themedir)      
    end
  end
end

Alula::Themes.install_themes