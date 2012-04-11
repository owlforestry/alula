require 'alula/engine/theme'

begin
  themes_dir = File.expand_path(File.join(File.dirname(__FILE__), %w{.. .. themes}))
  Dir[File.join(themes_dir, "*")].each do |theme_dir|
    name = File.basename(theme_dir)
    Alula::Engine::Theme.register name, theme_dir
  end
end
