module Alula
  class Engine
    class Processors
      attr_reader :file, :file_name, :file_ext, :asset_hash
      attr_reader :options, :engine, :config
      
      def initialize(attachment_file, options, engine)
        @file = attachment_file
        @file_name = File.basename(attachment_file)
        @file_ext = File.extname(attachment_file)[1..-1]
        
        @options = options
        @engine = engine
        @config = @engine.config
        
        # Generate asset filename
        @asset_hash = gen_assethash(File.join(options[:asset_path], self.file_name))
        
        set_mapping
      end
      
      def set_mapping(possix = nil)
        engine.attachment_mapping[File.join(options[:asset_path], self.file_name(possix))] = File.join(options[:asset_path], self.asset_name(possix))
      end
      
      def file_name(possix = nil)
        unless possix
          @file_name
        else
          File.join("#{File.basename(@file_name, ".#{@file_ext}")}#{possix}.#{@file_ext}")
        end
      end
      
      def asset_name(possix = nil, ext = nil)
        unless ext
          File.join("#{self.asset_hash}#{possix}#{File.extname(self.file_name).downcase}")
        else
          File.join("#{self.asset_hash}#{possix}#{ext[0] == "." ? ext : ".#{ext}"}")
        end
      end
      
      def process
        # Copy to originals if not existing already
        if !File.exists?(File.join(options[:original_path], "#{self.file_name}"))
          FileUtils.cp self.file, File.join(options[:original_path], "#{self.file_name}")
        end
      end
      
      def self.mimetype(re)
        (class << self; self; end).send(:define_method, "_mimetype") do
          re
        end
      end
      
      def self.extensions(*exts)
        (class << self; self; end).send(:define_method, "_extensions") do
          exts.collect {|e| ".#{e.to_s}" }
        end
      end
      
      def self.identify(file, opts = {})
        return false unless File.exists?(file)
        
        return true if self._extensions.include?(File.extname(file).downcase)
        
        return false if opts[:fast]
        
        exif = MiniExiftool.new file
        exif.mimetype.match(_mimetype)
      end
      
      def gen_assethash(name)
        md5 = Digest::MD5.hexdigest(name)
        asset_hash = md5[0..4]
        until !engine.attachment_mapping.key(asset_hash) or engine.attachment_mapping.key(asset_hash) == self.file_name
          asset_hash = md5[0..(asset_hash.length + 1)]
        end
        asset_hash.to_s
        
      end
    end
  end
end