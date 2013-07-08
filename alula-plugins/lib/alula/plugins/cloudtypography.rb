require 'alula/plugin'

module Alula
  class CloudTypography
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins cloudtypography})
    end
    
    def self.version
      Alula::Plugins::VERSION::STRING
    end
    
    def self.install(options)
      # Require valid cloud.typography token present in configuration
      return false unless options.token
      
      # Register addons
      Alula::Plugin.addon :head, ->(context) {
        "<link rel='stylesheet' type='text/css' href='//cloud.typography.com/#{options.token}/css/fonts.css' />"
      }
    end
  end
end

Alula::Plugin.register :cloudtypography, Alula::CloudTypography
