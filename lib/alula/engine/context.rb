require 'liquid/context'

module Alula
  class Engine
    class Context
      def initialize(data = {})
        @data = data
      end
      
      def []=(key, value)
        if value.kind_of?(Hash)
          value = Context.new value
        end
        @data[key] = value
      end
      
      def [](key)
        if @data[key].kind_of?(Hash)
          @data[key] = Context.new @data[key]
        end
        @data[key]
      end
      
      def data=(new_data)
        @data = new_data
      end
      
      def to_liquid
        context = Liquid::Context.new(nil, nil, :proxy => self)
        context.class.class_eval do
          def method_missing(meth, *args, &block)
            if registers[:proxy].respond_to?(meth.to_s)
              registers[:proxy].send(meth, *args)
            else
              super
            end
          end
        end
        context
      end
      
      def respond_to?(name)
        if name.to_s =~ /=$/ and @data.key?(name.to_s[0..-2])
          true
        elsif @data.key?(name)
          true
        else
          super
        end
      end
      
      def method_missing(meth, *args, &block)
        if meth.to_s =~ /=$/
          self.send(:[]=, meth.to_s[0..-2], *args)
        elsif @data.key?(meth.to_s)
          self.send(:[], meth.to_s)
        else
          super
        end
      end
    end
  end
end