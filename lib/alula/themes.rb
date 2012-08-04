require 'alula/theme'
require 'alula/themes/version'
require 'haml'

# Theme name, theme top-directory
# Alula::Theme.register :minimal, File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. themes})), Alula::Themes::VERSION
# Alula::Theme.register :phoflow, File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. themes})), Alula::Themes::VERSION

Dir[File.join(File.dirname(__FILE__), "themes", "*.rb")].each {|f| require f}
