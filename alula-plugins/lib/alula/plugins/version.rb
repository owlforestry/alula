module Alula
  module Plugins
    VERSION = File.read(File.join(File.dirname(__FILE__), %w{.. .. .. VERSION})).strip
  end
end
