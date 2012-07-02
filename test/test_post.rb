require "minitest_helper"
require 'alula/content/post'
require 'alula/config'

describe Alula::Content::Post do
  before do
    @site = MiniTest::Mock.new
    @site.expect :context, {}
    @site.expect :config, OpenStruct.new({permalinks: "/:year/:month/:title/", public_path: 'public'})
  end
  
  let :simple_post do
    File.join("test/fixtures/2012-07-02-simple.markdown")
  end
  
  let :invalid_post do
    File.join("test/fixtures/2012-07-02-invalid-post.markdown")
  end
  
  
  it "fails with non-existing file" do
    post = Alula::Content::Post.load(file: "non-existing.file", site: @site)
    post.must_be_nil
  end
  
  it "skips invalid post" do
    post = Alula::Content::Post.load(file: invalid_post, site: @site)
  end
  
  it "parses simple post" do
    post = Alula::Content::Post.load(file: simple_post, site: @site)
    post.metadata.title.must_equal "Simple Post"
    post.metadata.languages.must_be_nil
    
    # Parse and render
    post.send(:parse_liquid).must_equal "# Header\n\nThis is a simple post.\n"
    post.send(:parse_markdown).must_equal "<h1 id=\"header\">Header</h1>\n\n<p>This is a simple post.</p>\n"
    
    # Path and URI must be correct
    post.path.must_equal "public/2012/07/simple/index.html"
    post.url.must_equal "/2012/07/simple/"
  end
  
  it "renders content on simple post" do
    post = Alula::Content::Post.load(file: simple_post, site: @site)
    # post.render
  end
end