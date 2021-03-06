require "minitest_helper"
require 'alula/storages/file'
require 'ostruct'

describe "File Storage" do
  before do
    @site = MiniTest::Mock.new
    @config = {
      "content_path"      => 'test/fixtures',
      "pages_path"        => 'test/fixtures/pages',
      "posts_path"        => 'test/fixtures/posts',
      "attachments_path"  => 'test/fixtures/attachments',
      "public_path"       => 'public',
      }
  end
  
  it "accept simple configuration" do
    storage = Alula::Storage::File.new(@config, site: @site)
  end
  
  it "lists all posts" do
    storage = Alula::Storage::File.new(@config, site: @site)
    storage.posts.count.must_equal 4
    storage.post("2012-07-02-simple.markdown").wont_be_nil
  end
  
  it "list all pages" do
    storage = Alula::Storage::File.new(@config, site: @site)
    storage.pages.count.must_equal 4
    storage.page("simple-page.markdown").wont_be_nil
  end
end
