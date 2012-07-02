require "minitest_helper"
require 'alula/content/metadata'

describe Alula::Content::Metadata do
  it "loads empty metadata" do
    meta = Alula::Content::Metadata.new
    meta.title.must_be_nil
  end
  
  it "accepts simple metadata" do
    meta = Alula::Content::Metadata.new
    meta.title = "Simple Title"
    meta.title.must_equal "Simple Title"
  end
  
  it "load simple payload" do
    payload = <<-EOF
    title: Simple Title
    layout: default
    slug: another-slug
    EOF
    
    meta = Alula::Content::Metadata.new
    meta.load(payload)
    
    meta.title.must_equal "Simple Title"
    meta.layout.must_equal "default"
    meta.slug.must_equal "another-slug"
    
    meta.languages.must_be_nil
  end
  
  it "localised payload" do
    payload = <<-EOF
    title:
      en: Simple Title
      fi: Yksinkertainen otsikko
    layout:
      en: default
    slug:
      en: another-slug
      fi: yksinkertainen-otsikko
    EOF
    
    meta = Alula::Content::Metadata.new
    meta.load(payload)
    
    # Default language, i.e. first localisation
    meta.title.must_equal "Simple Title"
    meta.layout.must_equal "default"
    meta.slug.must_equal "another-slug"
    
    # Specific language
    meta.title("fi").must_equal "Yksinkertainen otsikko"
    meta.layout("fi").must_equal "default"
    meta.slug("fi").must_equal "yksinkertainen-otsikko"
    
    # Fetch proper languages list
    meta.languages.must_equal ["en", "fi"]
  end
  
  it "custom date setter" do
    require 'time'
    
    meta = Alula::Content::Metadata.new
    
    meta.date = "2012-07-02"
    meta.date.must_be_kind_of Time
    meta.date.year.must_equal 2012
    meta.date.month.must_equal 7
    meta.date.day.must_equal 2
    
    d = Time.parse("2012-07-02")
    meta.date = d
    meta.date.must_be_kind_of Time
    meta.date.year.must_equal d.year
    meta.date.month.must_equal d.month
    meta.date.day.must_equal d.day
    
    meta.date = "2012-13-45"
    meta.date.must_be_nil
  end
end