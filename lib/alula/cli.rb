require 'thor'
require 'alula/site'

module Alula
  class CLI < Thor
    include Thor::Actions
    
    source_root File.expand_path(File.join(File.dirname(__FILE__), *%w[.. .. template]))
    
    
    desc "init [PATH]", "Creates a new aLula blog in given path or current directory"
    def init(path = ".")
      # Create directory structure
      %w{attachments attachments/_originals attachments/_thumbnails posts}.each do |dir|
        empty_directory File.join(path, dir)
      end
      
      # Insert templates
      %w{Gemfile config.yml}.each do |tpl|
        template "#{tpl}.erb", File.join(path, tpl)
      end
      
      # Initialize system
      inside File.join(path) do
        run "bundle install"
      end
    end
    
    desc "generate", "Generates blog"
    method_option :development, :type => :boolean, :default => true,
      :desc => "Generate site using development settings. Keeps all assets and HTML uncompressed."
    method_option :production, :type => :boolean, :default => false,
      :desc => "Generate site using production settings. Compresses all assets and HTML."
    def generate
      site = Alula::Site.new("asset_compress" => (!options["development"] or options["production"]))
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
    
    desc "hello"
    def hello
      say "Hello world."
    end
  end
end