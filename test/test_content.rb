require "minitest_helper"
require 'alula/content'

describe "Content" do
  before do
    @site = MiniTest::Mock.new
    
    item = MiniTest::Mock.new
    item.expect :nil?, false
    item.expect :exists?, true
    item.expect :has_payload?, true
    item.expect :name, "item"
    item.expect :read, ""

    storage = MiniTest::Mock.new
    storage.expect :posts, { "item" => item }
    storage.expect :pages, { "item" => item }
    storage.expect :attachments, { "item" => item }
    @site.expect :storage, storage
  end
  
  it "loads site content" do
    @content = Alula::Content.new(site: @site)
    @content.load
    
    @content.pages.count.must_equal 1
    @content.posts.count.must_equal 1
    @content.attachments.count.must_equal 1
  end
end