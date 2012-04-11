module Alula
  class Engine
    class Filter
      attr_reader :options
      
      def initialize(opts = {})
        @options = opts
      end
      
      def filters?(type)
        return true if [:post, :page].include?(type)
      end
      
      # Dummy filter, just pass everything through
      def process(content)
        content
      end
    end
  end
end