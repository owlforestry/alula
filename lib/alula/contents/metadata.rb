require 'ostruct'

module Alula
  class Content
    class Metadata
      def initialize(default = {})
        default.each do |key, value|
          self.send("#{key}=", value)
        end
      end
      
      def load(payload)
        meta = YAML.load(payload)
        meta.each do |key, value|
          # Check for localisations
          self.send("#{key}=", value)
        end
      end
      
      def respond_to?(name)
        # Accept all setters
        return true if name.to_s =~ /=$/
        
        return true if instance_variable_defined?("@#{name}")
        
        super
      end
      
      def method_missing(meth, *args, &blk)
        if meth[/=$/]
          instance_variable_set("@#{meth[0..-2]}", *args)
        else
          # Localisation support
          value = instance_variable_get("@#{meth}")
          if value.kind_of?(Hash)
            if value.has_key?(args[0])
              # Make sure we always have string key
              value[args[0]]
            else
              value[@base_locale]
            end
          else
            value
          end
        end
      end
    
      # Custom accessors
      def date=(date)
        begin
          if date.kind_of?(String)
            @date = Time.parse(date)
          else
            @date = date
          end
        rescue ArgumentError => e
          @date = nil
        end
      end

      def languages(locale = nil)
        if @title.kind_of?(Hash)
          @title.keys
        else
          nil
        end
      end
    end
  end
end