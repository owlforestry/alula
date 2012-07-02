require 'liquid/context'

module Alula
  class Context
    def to_liquid
      @context ||= begin
        context = Liquid::Context.new(nil, nil, :proxy => self)
        context.class.class_eval do
          def method_missing(meth, *args, &blk)
            if registers[:proxy].respond_to?(meth.to_s)
              register[:proxy].send(meth, *args)
            else
              super
            end
          end
        end
      end
    end
  end
end
