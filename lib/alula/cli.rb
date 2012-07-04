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
    
    desc "preview", "Preview blog"
    method_option :development, :type => :boolean, :default => true,
      :desc => "Preview site using development settings. Keeps all assets and HTML uncompressed."
    method_option :production, :type => :boolean, :default => false,
      :desc => "Preview site suing production settings. Compresses all assets and HTML."
    method_option :verbose, :type => :boolean, :default => false,
      :desc => "Be verbose during site generation."
    method_option "skip-generate", :type => :boolean, :default => false,
      :desc => "Skip site generation before web server launch."
    def preview
      site = Alula::Site.new({
        "production" => (!options["development"] or options["production"]),
        "verbose" => options["verbose"],
        })
      site.generate unless options['skip-generate']
      
      # Start webserver
      begin
        require 'thin'
        require 'alula/support/commonlogger'
        
        s = Thin::Server.start('0.0.0.0', site.config.port) do
          @root = File.expand_path(site.storage.path(:public))
          use CommonLogger
          run Proc.new { |env|
            path = Rack::Utils.unescape(env['PATH_INFO'])
            index_file = File.join(@root, path, "index.html")
            
            if File.exists?(index_file)
              [200, {'Content-Type' => 'text/html'}, [File.read(index_file)]]
            else
              Rack::Directory.new(@root).call(env)
            end
          }
        end
      rescue LoadError => e
        puts "Please install thin gem to use preview functionality (gem install thin)."
      end
    end
  end
end
