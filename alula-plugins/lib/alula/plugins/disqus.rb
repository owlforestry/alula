require 'alula/plugin'

module Alula
  class Disqus
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins disqus})
    end
    
    def self.version
      Alula::Plugins::VERSION
    end
    
    def self.install(options)
      return false unless options.shortname
      # Force defer mode on script loading
      # Alula::Plugin.script_load_mode = :defer
      
      # Add Emphasis -powered link to footer
      Alula::Plugin.addon(:post_bottom, ->(context) {
        <<-EOS
        <script type="text/javascript">
        var disqus_shortname = '#{options['shortname']}';
        var disqus_identifier = '#{context.item.metadata.disqus_identifier || context.item.slug}';
        (function() {
          var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
          dsq.src = 'http://' + disqus_shortname + '.disqus.com/embed.js';
          (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
          })();
        </script>
        <a href="http://disqus.com" class="dsq-brlink">comments powered by <span class="logo-disqus">Disqus</span></a>
        EOS
      }
      )
    end
  end
end

Alula::Plugin.register :disqus, Alula::Disqus
