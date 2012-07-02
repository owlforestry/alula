require "minitest_helper"
require 'alula/content/page'

describe Alula::Content::Page do
  before do
    @site = MiniTest::Mock.new
    @site.expect :context, {}
  end
  
  let :simple_page do
    File.join("test/fixtures/simple-page.markdown")
  end
  
  let :invalid_page do
    File.join("test/fixtures/invalid-page.markdown")
  end
  
  
  it "fails with non-existing file" do
    page = Alula::Content::Page.load(file: "non-existing.file", site: nil)
  end
  
  it "loads simple page" do
    page = Alula::Content::Page.load(file: simple_page, site: nil)
  end
  
  it "skips invalid page" do
    page = Alula::Content::Page.load(file: invalid_page, site: nil)
  end
  
  it "parses simple post" do
    page = Alula::Content::Page.load(file: simple_page, site: @site)
    page.metadata.title.must_equal "Simple Page"
    page.metadata.languages.must_be_nil

    # Parse and render
    page.send(:parse_liquid).must_equal "# Header\n\nThis is a simple page.\n"

    page.send(:parse_markdown).must_equal "<h1 id=\"header\">Header</h1>\n\n<p>This is a simple page.</p>\n"
  end
end