module Alula
  class Smilies < Filter
    MAP = {
      smile: %w{:-) :) ^^ ^_^},
      sad: %w{:-( :(},
      laugh: %w{:-D :D},
    }
    SMILIES = Hash[*MAP.collect{|cls, keys| keys.collect{|key| [key, "<span class=\"smilies-#{cls}\">#{key}</span>"]}}.flatten]
    SMILIES_RE = Regexp.new(SMILIES.keys.collect{|k| Regexp.escape(k)}.join("|"))
    
    def process(content)
      content.gsub(SMILIES_RE, SMILIES)
    end
  end
end

Alula::Filter.register :smilies, Alula::Smilies