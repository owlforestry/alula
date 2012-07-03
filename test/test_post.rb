require "minitest_helper"
require 'alula/contents/post'
require 'alula/config'
require 'alula/storage'

describe Alula::Content::Post do
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
    item.expect :exists?, File.exists?("test/fixtures/posts/#{name}")
    item.expect :name, name
    if File.exists?("test/fixtures/posts/#{name}")
      item.expect :has_payload?, File.read("test/fixtures/posts/#{name}", 3) == "---"
      item.expect :read, File.read("test/fixtures/posts/#{name}")
    end

    item
  end
    
  let :missing_post do
    mock_item("invalid.file")
  end
  
  let :simple_post do
    mock_item("2012-07-02-simple.markdown")
  end
  
  let :metadata_post do
    mock_item("2012-07-03-full-metadata.markdown")
  end
  
  let :invalid_post do
    mock_item("2012-07-02-invalid-post.markdown")
  end
  
  let :complex_post do
    mock_item("2012-07-03-multilingual-full-metadata.markdown")
  end
  
  it "fails with non-existing file" do
    post = Alula::Content::Post.load(item: missing_post, site: @site)
    post.must_be_nil
  end
  
  it "skips invalid post" do
    post = Alula::Content::Post.load(item: invalid_post, site: @site)
  end
  
  it "parses simple post" do
    post = Alula::Content::Post.load(item: simple_post, site: @site)
    post.metadata.title.must_equal "Simple Post"
    post.metadata.languages.must_be_nil
    
    # Parse and render
    post.send(:parse_liquid).must_equal "# Header\n\nThis is a simple post.\n"
    post.send(:parse_markdown).must_equal "<h1>Header</h1>\n\n<p>This is a simple post.</p>\n"
    
    # Path and URI must be correct
    post.path.must_equal "/2012/07/simple-post/index.html"
    post.url.must_equal "/2012/07/simple-post/"
  end
  
  it "parses full metadata post" do
    post = Alula::Content::Post.load(item: metadata_post, site: @site)
    post.url.must_equal "/blog/path/to/long/nonce/to/get/nonce/"
    post.path.must_equal "/blog/path/to/long/nonce/to/get/nonce/index.html"
  end
  
  it "parses complex post" do
    @site.config.permalinks = "/:locale/:year/:month/:title/"
    @site.config.locale = "en"
    @site.config.hides_base_locale = true
    
    post = Alula::Content::Post.load(item: complex_post, site: @site)
    post.metadata.title.must_equal "Multilingual Post"
    post.metadata.languages.must_equal ["en", "fi"]
    post.metadata.title("fi").must_equal "Monikielinen kirjoitelma"
    
    post.url.must_equal "/2012/07/multilingual-post/"
    post.url("fi").must_equal "/fi/2012/07/monikielinen-kirjoitelma/"
    
    @site.config.hides_base_locale = false
    post = Alula::Content::Post.load(item: complex_post, site: @site)
    post.url.must_equal "/en/2012/07/multilingual-post/"
    
    @site.config.permalinks = "/:locale/:year/:slug"
    post = Alula::Content::Post.load(item: complex_post, site: @site)
    post.url("fi").must_equal "/fi/2012/monikielinen-blogi-kirjoitelma.html"
    post.path("fi").must_equal "/fi/2012/monikielinen-blogi-kirjoitelma.html"
  end
  
  it "renders content on simple post" do
    # Create mockup layout
    view = MiniTest::Mock.new
    view.expect :render, "<h1>Header</h1>", [{}]
    
    layout = MiniTest::Mock.new
    
    theme = MiniTest::Mock.new
    theme.expect :view, view, ["post"]
    
    site = MiniTest::Mock.new
    site.expect :context, {}
    site.expect :config, OpenStruct.new({locale: "en"})
    site.expect :theme, theme
    post = Alula::Content::Post.load(item: simple_post, site: site)
    
    # Render page using current layout, for all languages
    post.render
    post.content.must_equal "<h1>Header</h1>"
    
  end
end