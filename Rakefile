$:.unshift File.expand_path('..', __FILE__)
require "tasks/release"

# Versioning
require 'rake/version_task'
Rake::VersionTask.new do |task|
  task.with_git_tag = false
end

