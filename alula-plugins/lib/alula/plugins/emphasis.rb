require 'alula/plugin'

module Alula
  class Emphasis
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins emphasis})
    end
    
    def self.version
      Alula::Plugins::VERSION
    end
    
    def self.install(options)
      # Force defer mode on script loading
      Alula::Plugin.script_load_mode = :defer
      
      # Add Emphasis -powered link to footer
      Alula::Plugin.addon(:footer, "<a href=\"https://github.com/NYTimes/Emphasis\" title=\"Emphasis\">&para;</a>&nbsp;&ndash;Emphasis</a><br />")
    end
  end
end

Alula::Plugin.register :emphasis, Alula::Emphasis
