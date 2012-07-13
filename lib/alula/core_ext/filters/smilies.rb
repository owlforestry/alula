module Alula
  class Smilies < Filter
    MAP = {
      angel:       %w{:angel: },
      angry:       %w{:angry: },
      cool:        %w{:cool: },
      badguy:      %w{:badguy: },
      crying:      %w{:crying: ;( ;-( },
      exclamation: %w{:exclamation: },
      idea:        %w{:idea: },
      kiss:        %w{:kiss: :* :-* },
      laugh:       %w{:laugh: :D :-D },
      monkey:      %w{:monkey: },
      plain:       %w{:plain: :| :-| },
      question:    %w{:question: },
      tongue:      %w{:tongue: },
      sad:         %w{:sad: :( :-( },
      grin:        %w{:grin: },
      smile:       %w{:smile: :) :-) ^^ ^_^},
      smirk:       %w{:smirk: },
      point_right: %w{:point_right: },
      surprise:    %w{:surprise: },
      uncertain:   %w{:uncertain: },
      wink:        %w{:wink: ;) ;-) },
      worried:     %w{:worried: },
    }
    SMILIES = Hash[*MAP.collect{|cls, keys| keys.collect{|key| [key, "<span class=\"smilies-#{cls}\">#{key}</span>"]}}.flatten]
    SMILIES_RE = Regexp.new(SMILIES.keys.collect{|k| Regexp.escape(k)}.join("|"))
    
    def process(content, locale)
      content.gsub(SMILIES_RE, SMILIES)
    end
  end
end

Alula::Filter.register :smilies, Alula::Smilies