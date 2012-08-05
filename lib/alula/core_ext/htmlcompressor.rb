module HtmlCompressor
  class Compressor
    def profile
      @profile
    end
  
    def profile=(profile)
      @profile = profile
      case profile
      when :none
        @options[:enabled] = false
      when :normal
        @options[:enabled] = true
        @options[:remove_surrounding_spaces] = HtmlCompressor::Compressor::BLOCK_TAGS_MAX + ",source,title,meta,header,footer,div,section,article,time,img,video,script"
        @options[:remove_intertag_spaces] = true
        @options[:remove_quotes] = false
        @options[:remove_script_attributes] = true
        @options[:remove_style_attributes] = true
        @options[:remove_link_attributes] = true
        @options[:simple_boolean_attributes] = true
        @options[:remove_http_protocol] = false
        @options[:remove_https_protocol] = false
      when :high
        @options[:enabled] = true
        @options[:remove_surrounding_spaces] = HtmlCompressor::Compressor::BLOCK_TAGS_MAX + ",source,title,meta,header,footer,div,section,article,time,img,video,script"
        @options[:remove_intertag_spaces] = true
        @options[:remove_quotes] = true
        @options[:remove_script_attributes] = true
        @options[:remove_style_attributes] = true
        @options[:remove_link_attributes] = true
        @options[:simple_boolean_attributes] = true
        @options[:remove_http_protocol] = "href,src,cite,action,data-original,data-hires"
        @options[:remove_https_protocol] = "href,src,cite,action,data-original,data-hires"
      end
    end

    def remove_http_protocol(html)
      # remove http protocol from tag attributes
      if @options[:remove_http_protocol]
        pattern = case @options[:remove_http_protocol]
          when true
            HTTP_PROTOCOL_PATTERN
          else
            Regexp.new("(<[^>]+?(?:#{@options[:remove_http_protocol].gsub(",", "|")})\\s*=\\s*['\"])http:(//[^>]+?>)", Regexp::MULTILINE | Regexp::IGNORECASE)
          end
        html = html.gsub(pattern) do |match|
          group_1 = $1
          group_2 = $2

          if match =~ REL_EXTERNAL_PATTERN
            match
          else
            "#{group_1}#{group_2}"
          end
        end
      end

      html
    end

    def remove_https_protocol(html)
      # remove https protocol from tag attributes
      if @options[:remove_https_protocol]
        pattern = case @options[:remove_https_protocol]
          when true
            HTTPS_PROTOCOL_PATTERN
          else
            Regexp.new("(<[^>]+?(?:#{@options[:remove_https_protocol].gsub(",", "|")})\\s*=\\s*['\"])http:(//[^>]+?>)", Regexp::MULTILINE | Regexp::IGNORECASE)
          end

        html = html.gsub(pattern) do |match|
          group_1 = $1
          group_2 = $2

          if match =~ REL_EXTERNAL_PATTERN
            match
          else
            "#{group_1}#{group_2}"
          end
        end
      end

      html
    end

  end
end
