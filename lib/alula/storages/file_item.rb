require 'alula/storages/item'

module Alula
  class File
    class Item < Storage::Item
      def initialize(opts)
        super
      
        @file = opts.delete(:file)
      end
    
      def exists?
        ::File.file?(@file)
      end
      
      def has_payload?
        ::File.read(@file, 3) == "---"
      end
      
      def read
        ::File.read(@file)
      end
    end
  end
end