require 'alula/theme'
require 'haml'

# Theme name, theme top-directory
Alula::Theme.register :minimal, File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. themes}))
