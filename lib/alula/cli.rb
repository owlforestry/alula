require 'thor'
require 'alula/site'

module Alula
  class CLI < Thor
    include Thor::Actions
    
    TEMPLATE_DIR = File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    source_root TEMPLATE_DIR
    
    def self.generate_options
      option :development, :type => :boolean, :default => true,
        :desc => "Generate site using development settings. Keeps all assets and HTML uncompressed."
      option :production, :type => :boolean, :default => false,
        :desc => "Generate site using production settings. Compresses all assets and HTML."
      option :verbose, :type => :boolean, :default => false,
        :desc => "Be verbose during site generation."
      option :test, :type => :boolean, :default => false,
        :desc => "Turn on some testing features, i.e. doesn't upload/convert all files etc."
      option :debug, :type => :boolean, :default => false
    end    
    
    desc "version", "Displays current version information about loaded components"
    def version
      Alula::Version.print
    end
    
    desc "new [PATH]", "Creates a new empty blog"
    def new(path = ".")
      puts "Create blog at #{path}"
      
      # Init directories
      %w{content
        content/attachments content/pages content/posts content/static
        custom
        custom/images custom/javascripts custom/stylesheets}.each do |dir|
        empty_directory File.join(path, dir)
        create_file File.join(path, dir, ".gitkeep")
      end
      Dir[File.join(TEMPLATE_DIR, "**/*")].each do |tpl|
        name = tpl.gsub("#{TEMPLATE_DIR}/", '')
        if tpl[/\.erb$/]
          template tpl, File.join(path, name.gsub(/\.erb$/, ''))
        else
          copy_file tpl, File.join(path, name)
        end
      end
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
        "verbose"     => options["verbose"],
        "debug"       => options["debug"],
        "testing"     => options["test"]
      })
    end
  end
end
