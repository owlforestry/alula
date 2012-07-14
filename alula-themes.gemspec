# -*- encoding: utf-8 -*-
require File.expand_path('../lib/alula/themes/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikko Kokkonen"]
  gem.email         = ["mikko@owlforestry.com"]
  gem.description   = %q{Beatiful themes for Alula}
  gem.summary       = %q{Ready to use themes for Alula blogs.}
  gem.homepage      = "http://owlforestry.github.com/alula-themes"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "alula-themes"
  gem.require_paths = ["lib"]
  gem.version       = Alula::Themes::VERSION
  
  gem.add_dependency 'alula', '~> 0.4.0b'
  gem.add_dependency 'haml'
  
  gem.add_development_dependency 'version', '~> 1.0'
end
