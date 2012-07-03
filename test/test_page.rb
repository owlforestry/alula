require "minitest_helper"
require 'alula/contents/page'
require 'alula/storages/file'

describe Alula::Content::Page do
  before do
    @site = MiniTest::Mock.new
    @site.expect :context, {}
    @site.expect :config, OpenStruct.new({
      pagelinks: "/:locale/:slug/",
      permalinks: "/:year/:month/:title/",
      locale: "en", hides_base_locale: true,
      storage: { "file"     => {
        "content_path"      => 'test/fixtures',
        "pages_path"        => 'test/fixtures/pages',
        "posts_path"        => 'test/fixtures/posts',
        "attachements_path" => 'test/fixtures/attachements',
        "public_path"       => 'public',
        } }
      })
    
    @storage = Alula::Storage.load(site: @site, config: @site.config)
  end
  
  let :simple_page do
    @storage.page("simple-page.markdown")
  end
  
  let :invalid_page do
    @storage.page("invalid-page.markdown")
  end
  
  let :multilingual_page do
    @storage.page("multilingual-page.markdown")
  end
  
  let :subpage do
    @storage.page("section/subpage.markdown")
  end
  
  let :missing_page do
    @storage.page("missing.page")
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

    page.send(:parse_markdown).must_equal "<h1 id=\"header\">Header</h1>\n\n<p>This is a simple page.</p>\n"
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