require "minitest_helper"
require 'alula/config'

describe Alula::Config do
  it "loads default config" do
    config = Alula::Config.new()
    
    config.title.must_equal "The Unnamed Blog"
    config.url.must_equal "http://localhost:3000"
  end
  
  it "overrides given configurations" do
    config = Alula::Config.new(title: "Overriden fun")
    
    config.title.must_equal "Overriden fun"
    config.url.must_equal "http://localhost:3000"
  end
  
  it "loads project configuration" do
    config = Alula::Config.new({}, File.join("test/fixtures/config_001_simple.yml"))
    
    config.title.must_equal "Yet Another Blog"
    config.url.must_equal "http://localhost:3000"
  end

  it "loads project configuration with overrides" do
    config = Alula::Config.new({url: "http://lvh.me:3000"}, File.join("test/fixtures/config_001_simple.yml"))
    
    config.title.must_equal "Yet Another Blog"
    config.url.must_equal "http://lvh.me:3000"
  end

end