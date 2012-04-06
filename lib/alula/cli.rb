require 'thor'

module Alula
  class CLI < Thor
    include Thor::Actions
    
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
      
      # Initialize system
      inside File.join(path) do
        run "bundle install"
      end
    end
  end
end