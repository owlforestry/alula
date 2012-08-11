Dir[File.join(File.dirname(__FILE__), "plugins", "*.rb")].each {|f| require f}
