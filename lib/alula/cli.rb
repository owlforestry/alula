require 'thor'
require 'alula/site'
require 'yaml'

module Alula
  class CLI < Thor
    include Thor::Actions
    
    source_root File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    
    desc "version", "Displays current version information"
    def version
      puts "alula #{Alula::VERSION}"
      puts "alula-plugins #{Alula::Plugins::VERSION}" if Alula::Plugins::VERSION
      puts "alula-themes #{Alula::Themes::VERSION}" if Alula::Themes::VERSION
    end
    
    desc "init [PATH]", "Creates a new aLula blog in given path or current directory"
    def init(path = ".")
      @path = path
      
      # Init directories
      init_directories
      
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
      site = Alula::Site.new(:production => (!options["development"] or options["production"]), :verbose => options["verbose"])
      site.generate
    end

    desc "preview", "Preview blog"
    method_option :development, :type => :boolean, :default => true,
      :desc => "Preview site using development settings. Keeps all assets and HTML uncompressed."
    method_option :production, :type => :boolean, :default => false,
      :desc => "Preview site suing production settings. Compresses all assets and HTML."
    def preview
      site = Alula::Site.new("asset_compress" => (!options["development"] or options["production"]))
      site.preview
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
      %w{attachments attachments/originals posts pages}.each do |dir|
        empty_directory File.join(@path, dir)
      end
    end
    
    def default_config
      default     = {
        "author"  => "Your Name",
        "title"   => "My Blog",
        "tagline" => "Yet Another Blog",
        "theme"   => "minimal",
        
        "images"       => {
          "size"       => "800x600",
          "thumbnails" => "300x300",
          "retina"     => true,
        },
        
        "root"           => "/",
        "permalink"      => "/:year/:month/:title",
        "paginate"       => 10,
        "pagination_dir" => "/page",
        "excerpt_link"   => "Read on &rarr;",
        "plugins"        => {
          "lightbox"     => {},
        }
      }
      
      if File.exists?(File.join(@path, "config.yml"))
        if blog_config = YAML.load_file(File.join(@path, "config.yml"))
          # Place for mirgating settings
          default = default.deep_merge(blog_config)
        end
      end
      
      default
    end
  end
end
