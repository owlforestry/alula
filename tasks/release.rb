PROJECTS = %w( alula alula-plugins alula-themes )
root    = File.expand_path('../../', __FILE__)
version = File.read("#{root}/VERSION").strip
tag     = "v#{version}"

PROJECTS.each do |project|
  namespace project do
    gem     = "pkgs/#{project}-#{version}.gem"
    gemspec = "#{project}.gemspec"
    
    task :update_version_rb do
      file = "#{project}/lib/#{project.gsub('-', '/')}/version.rb"
      ruby = File.read(file)
      
      major, minor, patch = version.split('.')
      pre = pre ? pre.inspect : nil
      
      ruby.gsub!(/^(\s*)MAJOR = .*?$/, "\\1MAJOR = #{major}")
      raise "Could not insert MAJOR in #{file}" unless $1

      ruby.gsub!(/^(\s*)MINOR = .*?$/, "\\1MINOR = #{minor}")
      raise "Could not insert MINOR in #{file}" unless $1

      ruby.gsub!(/^(\s*)PATCH = .*?$/, "\\1PATCH = #{patch}")
      raise "Could not insert PATCH in #{file}" unless $1

      ruby.gsub!(/^(\s*)PRE   = .*?$/, "\\1PRE   = #{pre}")
      raise "Could not insert PRE in #{file}" unless $1
    end
    
    task gem => :update_version_rb do
      Dir.chdir(project) do
        system "gem build #{gemspec}"
        FileUtils.mv "#{project}-#{version}.gem", "#{root}/pkgs"
      end
    end
    
    task :build => gem
    task :install => [:build] do
      system "gem install #{gem}"
    end
    
    task :push => :build do
      system "gem push #{gem}"
    end
  end
end

namespace :all do
  task :build => PROJECTS.map { |p| "#{p}:build" }
  task :install => PROJECTS.map { |p| "#{p}:install" }
  task :push => PROJECTS.map { |p| "#{p}:push" }
  
  task :ensure_clean_state do
    unless `git status -s | grep -v VERSION`.strip.empty?
      abort "[ABORTING] `git status` reports a dirty tree. Make sure all changes are committed"
    end
    unless ENV['SKIP_TAG'] || `git tag | grep #{tag}`.strip.empty?
      abort "[ABORTING] `git tag` shows that #{tag} already exists. Has this version already\n"\
      "           been released? Git tagging can be skipped by setting SKIP_TAG=1"
    end
  end
  
  task :commit do
    unless `git status -s | grep -v VERSION`.strip.empty?
      File.open('pkgs/commit_message.txt', 'w') do |f|
        f.puts "# Preparing for #{version} release\n"
        f.puts
        f.puts "# UNCOMMENT THE LINE ABOVE TO APPROVE THIS COMMIT"
      end

      sh "git add . && git commit --verbose --template=pkgs/commit_message.txt"
      rm_f "pkgs/commit_message.txt"
    end
  end

  task :tag do
    sh "git tag -f #{tag}"
    sh "git push --tags"
  end

  desc "Build all gems and releases them to rubygems.org"
  task :release => [:ensure_clean_state, :build, :commit, :tag, :push]
end
