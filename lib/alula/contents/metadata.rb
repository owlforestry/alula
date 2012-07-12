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
            # Try environment & locale first
            if value.has_key?(environment) and value[environment].kind_of?(Hash)
              return value[environment][args[0]] if value[environment].has_key?(args[0])
              return value[environment][base_locale] if value[environment].has_key?(base_locale)
              return value[environment]
            else
              # Try locales
              return value[args[0]] if value.has_key?(args[0])
              return value[base_locale] if value.has_key?(base_locale)
              return value[environment] if value.has_key?(environment)
            end
          end
          
          value
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
          [base_locale]
        end
      end
    end
  end
end