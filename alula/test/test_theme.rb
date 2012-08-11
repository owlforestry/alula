require "minitest_helper"
require 'alula/theme'
require 'ostruct'

describe "Themes" do
  before do
    context = Object.new
    context.class.class_eval do
      def initialize; @vars = {}; end
      def [](key); @vars[key]; end
      def []=(key, val); @vars[key] = val; end
      def method_missing(meth, *args, &blk); return @vars[meth] if @vars; super; end
    end

    @site = MiniTest::Mock.new
    @site.expect :config, OpenStruct.new({theme: 'test'})
    @site.expect :context, context

    # Register our theme
    Alula::Theme.register(:test, "test/fixtures/theme")
  end
  
  it "doesn't load nonexisting theme" do
    @site.config.theme = "unknown"
    theme = Alula::Theme.load(site: @site)
    theme.must_be_nil
  end
  
  it "has working theme" do
    @site.config.theme = "test"
    theme = Alula::Theme.load(site: @site)
    theme.wont_be_nil
    
    # Find layout
    layout = theme.layout("default")
    layout.wont_be_nil
    
    # Find view
    view = theme.view("post")
    view.wont_be_nil
    
    # Test rendering
    view.render(content: "Theme Test").must_equal "<html><body><p>Theme Test</p></body></html>"
  end
end