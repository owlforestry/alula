require 'alula/plugin'

module Alula
  class Analytics
    def self.path
      File.join(File.dirname(__FILE__), %w{.. .. .. plugins analytics})
    end
    
    def self.version
      Alula::Plugins::VERSION
    end
    
    def self.install(options)
      return false unless options.kind_of?(Hash)
      
      options.each do |provider, opts|
        tracker = case provider
        when "chartbeat"
          Alula::Plugin.addon :head, ->(context) { "<script type=\"text/javascript\">var _sf_startpt=(new Date()).getTime()</script>"}
          <<-EOT
          <script type="text/javascript">var _sf_async_config={uid:#{opts['uid']},domain:"#{opts['domain']}"};(function(){function e(){window._sf_endpt=(new Date).getTime();var e=document.createElement("script");e.setAttribute("language","javascript"),e.setAttribute("type","text/javascript"),e.setAttribute("src",("https:"==document.location.protocol?"https://a248.e.akamai.net/chartbeat.download.akamai.com/102508/":"http://static.chartbeat.com/")+"js/chartbeat.js"),document.body.appendChild(e)}var t=window.onload;window.onload=typeof window.onload!="function"?e:function(){t(),e()}})();</script>
          EOT
        when "gosquared"
          <<-EOT
            <script type="text/javascript">var GoSquared={};GoSquared.acct="#{opts}",function(e){function t(){e._gstc_lt=+(new Date);var t=document,n=t.createElement("script");n.type="text/javascript",n.async=!0,n.src="//d1l6p2sc9645hc.cloudfront.net/tracker.js";var r=t.getElementsByTagName("script")[0];r.parentNode.insertBefore(n,r)}e.addEventListener?e.addEventListener("load",t,!1):e.attachEvent("onload",t)}(window);</script>
            EOT
        when "woopra"
          <<-EOT
          <script type="text/javascript">function woopraReady(e){return e.setDomain("#{opts}"),e.setIdleTimeout(3e5),e.track(),!1}(function(){var e=document.createElement("script");e.src=document.location.protocol+"//static.woopra.com/js/woopra.js",e.type="text/javascript",e.async=!0;var t=document.getElementsByTagName("script")[0];t.parentNode.insertBefore(e,t)})();</script>
          EOT
        end
        Alula::Plugin.addon(:body, ->(context) { tracker }) if tracker
      end
    end
  end
end

Alula::Plugin.register :analytics, Alula::Analytics
