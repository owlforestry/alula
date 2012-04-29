require 'thor'
require 'alula/site'
require 'yaml'

module Alula
  class CLI < Thor
    include Thor::Actions
    
    source_root File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    
    desc "version", "Displays current version information"
    def version
      require 'alula/version'
      puts "alula #{Alula::VERSION}"
      puts "alula-plugins #{Alula::Plugins::VERSION}" if defined? Alula::Plugins::VERSION
      puts "alula-themes #{Alula::Themes::VERSION}" if defined? Alula::Themes::VERSION
    end
    
    desc "init [PATH]", "Creates a new aLula blog in given path or current directory"
    def init(path = ".")
      @path = path
      
      # Init directories
      init_directories
      
      # Load default config
      default_config
      
      # Insert templates
      %w{Gemfile config.yml}.each do |tpl|
        template "#{tpl}.erb", File.join(path, tpl)
      end
      
      # Initialize system
      inside File.join(path) do
        run "bundle install"
      end
    end
    
    desc "upgrade", "Upgrades your Alula blog to newest version"
    def upgrade
      # Init directories
      init_directories
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
        s = Thin::Server.start('0.0.0.0', site.config.port) do
          @root = File.expand_path(site.config.public_path)
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
          # map "/" do
          #   run Rack::Directory.new("public")
          # end
        end
      end
    end
    
    desc "attach POST ASSET", "Attached given asset, photo or video to given post"
    def attach(post, *assets)
      site = Alula::Site.new
      site.asset_attach(post, assets)
    end
    
    desc "clean", "Clean up all generated content"
    def clean
      site = Alula::Site.new
      site.clean
    end
    
    private
    def init_directories
      # Create directory structure
      %w{attachments attachments/originals posts content static}.each do |dir|
        empty_directory File.join(@path, dir)
      end
    end
    
    def default_config
      @default_config ||= begin
        @default_config = Alula::Engine::Config::DEFAULT
        if File.exists?(File.join(@path, "config.yml"))
          if blog_config = YAML.load(File.read(File.join(@path, "config.yml")))
            # Place for migrating settings
            @default_config = @default_config.deep_merge(blog_config)
          end
        end
        @default_config
      end
      
      @default_config
    end
    
    private
    class CommonLogger
      # Common Log Format: http://httpd.apache.org/docs/1.3/logs.html#common
      # lilith.local - - [07/Aug/2006 23:58:02] "GET / HTTP/1.1" 500 -
      #             %{%s - %s [%s] "%s %s%s %s" %d %s\n} %
      FORMAT = %{[%s] %s %s\n}

      def initialize(app, logger=nil)
        @app = app
        @logger = logger
      end

      def call(env)
        status, header, body = @app.call(env)
        header = Rack::Utils::HeaderHash.new(header)
        body = Rack::BodyProxy.new(body) { log(env, status, header) }
        [status, header, body]
      end

      private

      def log(env, status, header)
        logger = @logger || env['rack.errors']
        logger.write FORMAT % [
          Time.now.strftime("%d/%b/%Y %H:%M:%S"),
          env["REQUEST_METHOD"],
          Rack::Utils.unescape(env["PATH_INFO"])]
      end
    end
  end
end
