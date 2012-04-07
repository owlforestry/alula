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
  
  gem.add_dependency 'jekyll', '~> 0.11.2'
  gem.add_dependency 'sprockets', '~> 2.4.0'
  gem.add_dependency 'thor', '~> 0.14.6'
  gem.add_dependency 'rmagick', '~> 2.13.1'
  gem.add_dependency 'sass', '~> 3.1.15'
  gem.add_dependency 'coffee-script', '~> 2.2.0'
  gem.add_dependency 'uglifier', '~> 1.2.4'
  gem.add_dependency 'front-compiler', '~> 1.1.0'
  gem.add_dependency 'activesupport', '~> 3.2.3'
  gem.add_dependency 'stringex', '~> 1.3.2'
  gem.add_dependency 'ruby-progressbar', '~> 0.0.10'

  gem.add_development_dependency 'version', '~> 1.0.0'
end
