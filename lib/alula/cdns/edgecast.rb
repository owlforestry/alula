module Alula
  class Edgecast < CDN
    THRESHOLD = 300 * 1024 # 300kB
    
    def url_for(name, opts)
      file = opts.delete(:file)
      
      hosts = File.size(file) < THRESHOLD ? self.options.small : self.options.large
      
      host = hosts[Digest::MD5.hexdigest(name).to_i(16) % hosts.count]
      File.join(host, name)
    end
  end
end

Alula::CDN.register :edgecast, Alula::Edgecast
