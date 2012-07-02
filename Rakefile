#!/usr/bin/env rake
require "bundler/setup"
require "bundler/gem_tasks"

# Versioning
require 'rake/version_task'
Rake::VersionTask.new

# Tests
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.pattern = "test/**/*_test.rb"
end

task :default => :test
