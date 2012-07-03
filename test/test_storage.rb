require "minitest_helper"
require 'alula/storage'
require 'ostruct'

describe "Storage" do
  before do
    @site = MiniTest::Mock.new
    @site.expect :config, OpenStruct.new({})
  end
  
  it "loads proper provider" do
    puts ":: #{@site.config.storage.inspect}"
    @site.config.storage = {"none" => {}}
    storage = Alula::Storage.load(site: @site)
    storage.must_be_nil
    
    @site.config.storage = {"file" => { "content_path" => 'test/fixtures', "pages_path" => 'test/fixtures/pages',
      "posts_path" => 'test/fixtures/posts', "attachements_path" => 'test/fixtures/attachements', "public_path" => 'public' }}
    storage = Alula::Storage.load(site: @site)
    storage.wont_be_nil
    
  end
end
