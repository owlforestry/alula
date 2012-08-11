# -*- encoding: utf-8 -*-
require File.expand_path('../lib/alula/plugins/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikko Kokkonen"]
  gem.email         = ["mikko@owlforestry.com"]
  gem.description   = %q{Plugins for Alula blog}
  gem.summary       = %q{Simple, ready to use plugins for Alula blogs.}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "alula-plugins"
  gem.require_paths = ["lib"]
  gem.version       = Alula::Plugins::VERSION
  
  gem.add_dependency 'alula', '~> 0.4.0'

  gem.add_development_dependency 'version', '~> 1.0.0'
end
