require 'thor'
require 'alula/site'
if File.exists?("Gemfile")
  require 'bundler'
  Bundler.require
end

module Alula
  class CLI < Thor
    include Thor::Actions
    
    TEMPLATE_DIR = File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    source_root TEMPLATE_DIR
    
    def self.generate_options
      # option :development, :type => :boolean, :default => true,
      #   :desc => "Generate site using development settings. Keeps all assets and HTML uncompressed."
      # option :production, :type => :boolean, :default => false,
      #   :desc => "Generate site using production settings. Compresses all assets and HTML."
      option :environment, :type => :string, :default => 'development', :aliases => "-e",
        :desc => "Environment where site is built"
      option :verbose, :type => :boolean, :default => false, :aliases => "-v",
        :desc => "Be verbose during site generation."
      option :test, :type => :boolean, :default => false, :aliases => "-t",
        :desc => "Turn on some testing features, i.e. doesn't upload/convert all files etc."
      option :debug, :type => :boolean, :default => false, :aliases => "-d"
    end    
    
    desc "version", "Displays current version information about loaded components"
    def version
      puts "Alula #{Alula::VERSION::STRING}"
    end
    
    desc "new [PATH]", "Creates a new empty blog"
    option :edge, :type => :boolean, :default => false, :desc => "Use edge version from GIT"
    option :path, :type => :string, :desc => "Use given path as alula source"
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
      
      inside File.expand_path(path) do
        # Try to find git
        git=%x{/usr/bin/which git}.strip
        if File.executable?(git) and !File.directory?(".git")
          run "#{git} init"
        end

        # Run bundle command
        run "bundle install"
      end
    end
    
    desc "generate", "Generates blog"
    generate_options
    def generate(*args)
      unless args.empty?
        args.each {|a| puts "Unknown option #{a} given."}; exit
      end
      site.generate
    end
    
    desc "deploy", "Deploys a blog"
    generate_options
    def deploy(*args)
      unless args.empty?
        args.each {|a| puts "Unknown option #{a} given."}; exit
      end
      site.deploy
    end
    
    desc "preview", "Preview blog"
    generate_options
    option "skip-generate", :type => :boolean, :default => false, :aliases => "-s",
      :desc => "Skip site generation before web server launch."
    def preview(*args)
      unless args.empty?
        args.each {|a| puts "Unknown option #{a} given."}; exit
      end
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
        "environment" => options["environment"],
        "verbose"     => options["verbose"],
        "debug"       => options["debug"],
        "testing"     => options["test"]
      })
    end
  end
end
