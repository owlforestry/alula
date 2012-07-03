require 'alula/storage'
require 'alula/storages/file_item'

module Alula
  class Storage::File < Storage
    def initialize(options, opts)
      super
      
      # Check we have given directories
      %w{content_path posts_path pages_path attachements_path}.each do |dir|
        raise "Directory #{options[dir]} for #{dir} does not exists!" unless ::File.directory?(options[dir])
      end
    end
    
    # List all posts
    def posts
      @posts ||= _list_all_in(self.options["posts_path"])
    end
    
    def pages
      @pages ||= _list_all_in(self.options["pages_path"])
    end
    
    private
    def _list_all_in(path)
      items = {}
      Dir[::File.join(path, "**", "*")].each do |item|
        next unless ::File.file?(item)
        name = item.gsub("#{path}/", '')
        items[name] = File::Item.new(name: name, file: item, storage: self)
      end
      items
    end
  end
end