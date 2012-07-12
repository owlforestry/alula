require 'alula/storages/item'

module Alula
  class Storage::FileItem < Storage::Item
    def initialize(opts)
      super
    
      @file = opts.delete(:file)
    end
  
    def exists?
      ::File.file?(@file)
    end
    
    def extension
      ::File.extname(@file)[1..-1]
    end
    
    def filepath
      @file
    end
    
    def has_payload?
      ::File.read(@file, 3) == "---"
    end
    
    def size
      ::File.size(@file)
    end
    
    def mtime
      ::File.mtime(@file)
    end
    
    def read
      ::File.read(@file)
    end
    
    def open
      ::File.open(@file)
    end
  end
end
