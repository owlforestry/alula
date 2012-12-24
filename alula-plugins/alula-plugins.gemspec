version = File.read(File.expand_path("../../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'alula-plugins'
  s.version     = version
  s.summary     = 'Basic plugins and extenstions for Alula blogs (part of Alula).'
  s.description = 'Offers simple collection of basic plugins that are not necessary needed for every blog.'
  s.required_ruby_version = '>= 1.9.3'
  s.license     = 'MIT'
  
  s.author    = "Mikko Kokkonen"
  s.email     = "mikko@owlforestry.com"
  s.homepage  = "http://www.alula.in"

  # s.executables   = Dir["bin/*"].map{ |f| File.basename(f) }
  s.files         = Dir['CHANGELOG.md', 'README.md', 'MIT-LICENSE', 'lib/**/*', 'plugins/**/*']
  s.require_path  = "lib"
  s.requirements << 'none'
  
  s.add_dependency 'alula', version
end
