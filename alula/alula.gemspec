version = File.read(File.expand_path("../../VERSION", __FILE__)).strip

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'alula'
  s.version     = version
  s.summary     = 'Alula is simple, static blog generator.'
  s.description = 'Alula creates higly optimised static blogs while taking all the complexity and repeated tasks away from you.'
  s.required_ruby_version = '>= 1.9.3'
  s.license     = 'MIT'
  
  s.author    = "Mikko Kokkonen"
  s.email     = "mikko@owlforestry.com"
  s.homepage  = "http://www.alula.in"

  s.executables   = Dir["bin/*"].map{ |f| File.basename(f) }
  s.files         = Dir['CHANGELOG.md', 'README.ms', 'MIT-LICENSE', 'lib/**/*']
  s.require_path  = "lib"
  s.requirements << 'none'
  
  # s.add_dependency 'parallel'
  s.add_dependency 'hashie', '~> 1.2'
  s.add_dependency 'thin', '~> 1.4'
  s.add_dependency 'tilt', '~> 1.3'
  s.add_dependency 'liquid', '~> 2.4'
  s.add_dependency 'builder', '~> 3.0'
  s.add_dependency 'kramdown', '~> 0.13'
  s.add_dependency 'sprockets', '~> 2.4'
  s.add_dependency 'thor', '~> 0.14'
  s.add_dependency 'i18n', '~> 0.6'
  s.add_dependency 'rmagick', '~> 2.13'
  s.add_dependency 'sass', '~> 3.2'
  s.add_dependency 'coffee-script', '~> 2.2'
  s.add_dependency 'uglifier', '~> 1.2'
  s.add_dependency 'htmlcompressor', '~> 0.0.3'
  s.add_dependency 'stringex', '~> 1.3'
  s.add_dependency 'powerbar', '~> 1.0'
  s.add_dependency 'mimemagic', '~> 0.1'
  s.add_dependency 'aws-sdk', '~> 1.6'
  s.add_dependency 'zencoder', '~> 2.4'
  s.add_dependency 'mini_exiftool', '~> 1.3'
  s.add_dependency 'dimensions', '~> 1.2'
  s.add_dependency 'htmlentities', '~> 4.3'

  s.add_development_dependency 'minitest', '~> 3.3'
  s.add_development_dependency 'turn', '~> 0.9'
  s.add_development_dependency 'simplecov', '~> 0.6'
end
