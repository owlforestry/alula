require 'alula/plugin'

module Alula
  class Analytics
    Alula::Plugin.needs_cookieconsent
    
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins analytics})
    end
    
    def self.version
      Alula::Plugins::VERSION::STRING
    end
    
    def self.install(options)
      return false unless options.kind_of?(Hash)
      
      options.each do |provider, opts|
        tracker = case provider
        when "chartbeat"
          Alula::Plugin.script :head, "var _sf_startpt=(new Date()).getTime()"
          <<-EOT
          var _sf_async_config={uid:#{opts['uid']},domain:"#{opts['domain']}"};(function(){function e(){window._sf_endpt=(new Date).getTime();var e=document.createElement("script");e.setAttribute("language","javascript"),e.setAttribute("type","text/javascript"),e.setAttribute("src",("https:"==document.location.protocol?"https://a248.e.akamai.net/chartbeat.download.akamai.com/102508/":"http://static.chartbeat.com/")+"js/chartbeat.js"),document.body.appendChild(e)}var t=window.onload;window.onload=typeof window.onload!="function"?e:function(){t(),e()}})();
          EOT
        when "gosquared"
          <<-EOT
          var GoSquared={};GoSquared.acct="#{opts}",function(e){function t(){e._gstc_lt=+(new Date);var t=document,n=t.createElement("script");n.type="text/javascript",n.async=!0,n.src="//d1l6p2sc9645hc.cloudfront.net/tracker.js";var r=t.getElementsByTagName("script")[0];r.parentNode.insertBefore(n,r)}e.addEventListener?e.addEventListener("load",t,!1):e.attachEvent("onload",t)}(window);
          EOT
        when "woopra"
          <<-EOT
          function woopraReady(e){return e.setDomain("#{opts}"),e.setIdleTimeout(3e5),e.track(),!1}(function(){var e=document.createElement("script");e.src=document.location.protocol+"//static.woopra.com/js/woopra.js",e.type="text/javascript",e.async=!0;var t=document.getElementsByTagName("script")[0];t.parentNode.insertBefore(e,t)})();
          EOT
        when "gauges"
          <<-EOT
          var _gauges=_gauges||[];(function(){var e=document.createElement("script");e.type="text/javascript",e.async=!0,e.id="gauges-tracker",e.setAttribute("data-site-id","#{opts}"),e.src="//secure.gaug.es/track.js";var t=document.getElementsByTagName("script")[0];t.parentNode.insertBefore(e,t)})();
          EOT
        end
        Alula::Plugin.script(:body, tracker) if tracker
      end
    end
  end
end

Alula::Plugin.register :analytics, Alula::Analytics
