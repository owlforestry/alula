xml.instruct! :xml, :version => "1.0" 
xml.rss :version => "2.0" do
  xml.channel do
    xml.title site.title
    xml.description site.tagline
    xml.link site.url
    xml.lastBuildDate Time.now.strftime("%a, %d %b %Y %H:%M:%S %z")
    xml.generator "Alula #{Alula::VERSION}"
    
    for post in engine.posts[0..(config.feed_posts - 1)]
      xml.item do
        xml.title { xml.cdata! post.title }
        xml.description { xml.cdata! post.content }
        xml.pubDate post.date.strftime("%a, %d %b %Y %H:%M:%S %z")
        xml.link "#{site.url}/#{post.url}"
      end
    end
  end
end
