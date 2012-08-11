module Alula
  class Hosts < CDN
    def url_for(name, opts)
      if self.options[0] == "/"
        File.join("/", name)
      else
        host = self.options[Digest::MD5.hexdigest(name).to_i(16) % self.options.count]
        File.join(host, name)
      end
    end
  end
end

Alula::CDN.register :hosts, Alula::Hosts