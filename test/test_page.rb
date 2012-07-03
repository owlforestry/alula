require "minitest_helper"
require 'alula/contents/page'

describe Alula::Content::Page do
  before do
    @site = MiniTest::Mock.new
    @site.expect :context, {}
    @site.expect :config, OpenStruct.new({
      permalinks: "/:year/:month/:title/",
      pagelinks: "/:locale/:slug/",
      locale: "en", hides_base_locale: true,
    })
  end
  
  def mock_item(name)
    item = MiniTest::Mock.new
    item.expect :nil?, false
    item.expect :exists?, File.exists?("test/fixtures/pages/#{name}")
    item.expect :name, name
    if File.exists?("test/fixtures/pages/#{name}")
      item.expect :has_payload?, File.read("test/fixtures/pages/#{name}", 3) == "---"
      item.expect :read, File.read("test/fixtures/pages/#{name}")
    end

    item
  end
  
  let :simple_page do
    mock_item("simple-page.markdown")
  end
  
  let :invalid_page do
    mock_item("invalid-page.markdown")
  end
  
  let :multilingual_page do
    mock_item("multilingual-page.markdown")
  end
  
  let :subpage do
    mock_item("section/subpage.markdown")
  end
  
  let :missing_page do
    mock_item("missing.page")
  end
  
  it "fails with non-existing file" do
    page = Alula::Content::Page.load(item: missing_page, site: @site)
  end
  
  it "loads simple page" do
    page = Alula::Content::Page.load(item: simple_page, site: @site)
  end
  
  it "skips invalid page" do
    page = Alula::Content::Page.load(item: invalid_page, site: @site)
  end
  
  it "parses simple post" do
    page = Alula::Content::Page.load(item: simple_page, site: @site)
    page.metadata.title.must_equal "Simple Page"
    page.metadata.languages.must_be_nil

    # Parse and render
    page.send(:parse_liquid).must_equal "# Header\n\nThis is a simple page.\n"

    page.send(:parse_markdown).must_equal "<h1>Header</h1>\n\n<p>This is a simple page.</p>\n"
  end
  
  it "parses multilingual page" do
    page = Alula::Content::Page.load(item: multilingual_page, site: @site)
    page.url.must_equal "/about/"
    page.url("fi").must_equal "/fi/mina/"
  end
  
  it "parses subpages" do
    page = Alula::Content::Page.load(item: subpage, site: @site)
    page.url.must_equal "/section/subpage/"
  end
end