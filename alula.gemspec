# -*- encoding: utf-8 -*-
require File.expand_path('../lib/alula/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikko Kokkonen"]
  gem.email         = ["mikko@owlforestry.com"]
  gem.description   = %q{Alula is a simple tool for creating fast, static blogs easily.}
  gem.summary       = %q{Alula is a collection of useful tools that makes generating Jekyll blog as
     easy as typing couple commands. Alula takes care of optimizing, handling all assets for you.}
  gem.homepage      = "http://owlforestry.github.com/alula"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "alula"
  gem.require_paths = ["lib"]
  gem.version       = Alula::VERSION
  
  gem.add_dependency 'jekyll'
  gem.add_dependency 'sprockets'
  gem.add_dependency 'thor'
  gem.add_dependency 'rmagick'
  gem.add_dependency 'sass'
  gem.add_dependency 'coffee-script'
  gem.add_dependency 'uglifier'
  gem.add_dependency 'activesupport'
end
