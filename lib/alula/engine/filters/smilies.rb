module Alula
  class Engine
    class Filter
      class Smilies < Filter
        MAP = {
          "smile" => [":-)", ":)", "^^", "^_^"],
          "sad"   => [":-(", ":("],
          "laugh" => [":-D", ":D"],
        }
        
        def initialize(opts)
          super
          
          @smilies = {}
          MAP.each do |cls, keys|
            keys.each do |key|
              @smilies[key] = "<span class=\"smilies-#{cls}\">#{key}</span>"
            end
          end
          @smilies_re = Regexp.new(@smilies.keys.collect{|k| Regexp.escape(k)}.join("|"))
        end
        
        def process(content)
          content.gsub(@smilies_re, @smilies)
        end
      end
    end
  end
end
