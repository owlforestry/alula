
version = File.read(File.expand_path("../../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'alula-themes'
  s.version     = version
  s.summary     = 'Basic themes for Alula blogs (part of Alula).'
  s.description = 'Offers default theme as well some basic themes for Alula blogs.'
  s.required_ruby_version = '>= 1.9.3'
  s.license     = 'MIT'
  
  s.author    = "Mikko Kokkonen"
  s.email     = "mikko@owlforestry.com"
  s.homepage  = "http://www.alula.in"

  # s.executables   = Dir["bin/*"].map{ |f| File.basename(f) }
  s.files         = Dir['CHANGELOG.md', 'README.ms', 'MIT-LICENSE', 'lib/**/*']
  s.require_path  = "lib"
  s.requirements << 'none'
  
  s.add_dependency 'alula', version
  
  s.add_dependency 'alula', version
  s.add_dependency 'haml', '~> 3.1'
end
