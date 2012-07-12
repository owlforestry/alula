# require 'alula/storage'
require 'alula/storages/file_item'

module Alula
  class Storage::FileStorage < Storage
    def initialize(options, opts)
      super
  
      # Check we have given directories
      %w{content_path posts_path pages_path attachments_path}.each do |dir|
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

    def attachments
      @attachments ||= _list_all_in(self.options["attachments_path"])
    end

    def customs
      @customs ||= _list_all_in(self.options["custom_path"])
    end
    
    def path(type, *appendum)
      dirname = case type
      when :public
        File.join(self.options["public_path"])
      when :custom
        File.join(self.options["custom_path"])
      when :assets
        File.join(self.options["public_path"], "assets")
      when :cache
        File.join(self.options["cache_path"])
      end

      dirname = File.join(dirname, appendum) if appendum
      
      FileUtils.mkdir_p dirname unless File.directory?(dirname)
      
      dirname
    end
    
    # 
    def prepare(preserve = false)
      if !preserve
        FileUtils.rm_rf self.options["public_path"]
      end
  
      FileUtils.mkdir_p self.options["public_path"]
    end

    def output(path)
      fname = ::File.join(self.options["public_path"], path)
      dirname = ::File.dirname(fname)
      FileUtils.mkdir_p dirname unless ::File.directory?(dirname)
  
      ::File.open(fname, "w") do |io|
        io.puts yield io
      end
    end

    private
    def _list_all_in(path)
      items = {}
      Dir[::File.join(path, "**", "*")].each do |item|
        next unless ::File.file?(item)
        name = item.gsub("#{path}/", '')
        items[name] = FileItem.new(name: name, file: item, storage: self)
      end
      items
    end
  end
end
