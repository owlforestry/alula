xml.instruct! :xml, :version => "1.0" 
xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do
  for url in item.urls.call(self)
    xml.url do
      xml.loc url_for(url[:url])
      xml.lastmod url[:lastmod].strftime('%Y-%m-%d') if url[:lastmod]
      xml.priority url[:priority] if url[:priority]
    end
  end
end
