require 'thor'
require 'alula/site'

module Alula
  class CLI < Thor
    include Thor::Actions
    
    source_root File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    
    desc "version", "Displays current version information about loaded components"
    def version
      Alula::Version.print
    end
    
    desc "generate", "Generates blog"
    method_option :development, :type => :boolean, :default => true,
      :desc => "Generate site using development settings. Keeps all assets and HTML uncompressed."
    method_option :production, :type => :boolean, :default => false,
      :desc => "Generate site using production settings. Compresses all assets and HTML."
    method_option :verbose, :type => :boolean, :default => false,
      :desc => "Be verbose during site generation."
    def generate
      site = Alula::Site.new({
        "production" => (!options["development"] or options["production"]),
        "verbose" => options["verbose"]
      })
      site.generate
    end
  end
end
