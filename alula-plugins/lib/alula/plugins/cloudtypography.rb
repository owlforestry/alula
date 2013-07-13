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
      # Require valid cloud.typography userid and project present in configuration
      return false unless options.userid
      return false unless options.project
      
      # Register addons
      Alula::Plugin.addon :head, ->(context) {
        "<link rel='stylesheet' type='text/css' href='//cloud.typography.com/#{options.userid}/#{options.project}/css/fonts.css' />"
      }
    end
  end
end

Alula::Plugin.register :cloudtypography, Alula::CloudTypography
