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
      
      # Create Gemfile
      create_file File.join(path, "Gemfile") do
        <<EOF
source :rubygems

gem "alula"
gem "alula-plugins"
gem "alula-themes"
EOF
      end
      
      # Create Rakefile
      create_file File.join(path, "Rakefile")  do
        <<EOF
require 'rubygems'
require "bundler/setup"
Bundler.require(:default)

require 'alula/tasks'
EOF
      end
      
      # Create config
      template "config.yml.erb", File.join(path, "config.yml")
      
      # Initialize system
      inside File.join(path) do
        run "bundle install"
      end
    end
  end
end