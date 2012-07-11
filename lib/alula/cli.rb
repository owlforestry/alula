require 'thor'
require 'alula/site'

module Alula
  class CLI < Thor
    include Thor::Actions
    
    source_root File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    
    def self.generate_options
      option :development, :type => :boolean, :default => true,
        :desc => "Generate site using development settings. Keeps all assets and HTML uncompressed."
      option :production, :type => :boolean, :default => false,
        :desc => "Generate site using production settings. Compresses all assets and HTML."
      option :verbose, :type => :boolean, :default => false,
        :desc => "Be verbose during site generation."
      option :debug, :type => :boolean, :default => false
    end    
    
    desc "version", "Displays current version information about loaded components"
    def version
      Alula::Version.print
    end
    
    desc "generate", "Generates blog"
    generate_options
    def generate
      site.generate
    end
    
    desc "preview", "Preview blog"
    generate_options
    option "skip-generate", :type => :boolean, :default => false,
      :desc => "Skip site generation before web server launch."
    def preview
      site.generate unless options['skip-generate']
            
      # Start webserver
      begin
        require 'thin'
        require 'alula/support/commonlogger'
        
        public_path = site.storage.path(:public)
        s = Thin::Server.start('0.0.0.0', site.config.port) do
          @root = File.expand_path(public_path)
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
    
    private
    def site
      @site ||= Alula::Site.new({
        "environment" => (!options["development"] or options["production"]) ? "production" : "development",
        "verbose" => options["verbose"],
        "debug" => options["debug"],
      })
    end
  end
end
