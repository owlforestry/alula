require 'alula/theme/view'
require 'tilt'
require 'sass'  # As suggested by tilt

module Alula
  class Theme
    class Layout
      attr_reader :theme
      attr_reader :name
      attr_reader :context

      def initialize(opts)
        @theme = opts.delete(:theme)
        @name = opts.delete(:name)
        @file = opts.delete(:file)
        
        @views = {}
        
        @context = @theme.context
        
        @template = Tilt.new(@file)
      end
      
      def view(name)
        @views[name] ||= begin
          # Find our layout name
          file = Dir[::File.join(self.theme.path, "views", "#{name}.*")].first
          if file
            View.new(layout: self, name: name, file: file)
          end
        end
      end
      
      def render(content, &blk)
        _old_values = {}
        
        # Set up context, make sure we don't change anything
        begin
          content.each do |key, value|
            _old_values[key] = self.context[key]
            self.context[key] = value
          end
          
          # Render using our layout template
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