xml.instruct! :xml, :version => "1.0" 
xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do
  for url in item.urls
    xml.url do
      xml.loc url_for(url)
    end
  end
end
