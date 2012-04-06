require 'alula/site'

module Alula
  class RakeTasks
    include Rake::DSL if defined? Rake::DSL
    
    def self.install_tasks
      self.new().install
    end
    
    def initialize
    end
    
    def install
      desc "Generate Alula blog (development)"
      task :generate do
        puts "==> Generating blog..."
        site = Alula::Site.new
        site.generate
      end
      
      desc "Starts previw mode by development server"
      task :preview do
        puts "==> Starting preview"
        site = Alula::Site.new
        site.preview
      end
    end
  end
end
