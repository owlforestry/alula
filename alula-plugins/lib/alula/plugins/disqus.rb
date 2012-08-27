require 'alula/plugin'

module Alula
  class Disqus
    Alula::Plugin.needs_cookieconsent
    
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins disqus})
    end
    
    def self.version
      Alula::Plugins::VERSION::STRING
    end
    
    def self.install(options)
      return false unless options.shortname
      
      Alula::Plugin.script(:post_bottom, ->(context) {
        <<-EOS
        var disqus_shortname = '#{options['shortname']}';
        var disqus_identifier = '#{context.item.metadata.disqus_identifier || context.item.slug}';
        (function() {
          var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
          dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
          (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
          })();
        EOS
      }
      )
    end
  end
end

Alula::Plugin.register :disqus, Alula::Disqus
