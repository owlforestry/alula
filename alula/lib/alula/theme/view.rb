require 'tilt'

module Alula
  class Theme
    class View
      attr_reader :theme
      attr_reader :layout
      attr_reader :context
      
      def initialize(opts)
        @theme = opts.delete(:theme)
        @name = opts.delete(:name)
        @file = opts.delete(:file)
        
        # Shortcuts...
        @context = @theme.context
        
        # Load our template
        @template = Tilt.new(@file, nil, @theme.options(@file))
      end
      
      def render(content, &blk)
        _old_values = {}
        
        # Set up context, make sure we don't change anything
        begin
          content.each do |key, value|
            _old_values[key] = self.context[key]
            self.context[key] = value
          end
          
          # Render using our template
          @template.render(self.context, &blk)
          
        ensure
          _old_values.each do |key, value|
            self.context[key] = value
          end
        end
      end
    end
  end
end
