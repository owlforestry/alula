require 'alula/engine/processors/image'
require 'alula/engine/processors/video'
# require 'alula/engine/processors/audio' # Placeholder

module Alula
  class Engine
    class AttachmentProcessor
      attr_reader :engine, :config
      def initialize(engine)
        @engine = engine
        @config = @engine.config
      end
      
      def process(attachment, options = {})
        # Inject some path defaults
        asset_path = options[:asset_path] # Simple shortcut
        
        options           = {
          :image_path     => File.join(config.attachments_path, "_generated", "images", asset_path),
          :thumbnail_path => File.join(config.attachments_path, "_generated", "thumbnails", asset_path),
          :original_path  => File.join(config.attachments_path, "originals", asset_path),
        }.deep_merge(options)
        attachment_file = File.join(options[:path], attachment)
        
        # Create necessary directories
        [:image_path, :thumbnail_path].each { |p| FileUtils.mkdir_p options[p] }
        
        # Find our processor
        processor = Alula::Engine::Processors.constants.collect{|p| Alula::Engine::Processors.const_get(p) }.select do |processor|
          processor.identify(attachment_file, :fast => true)
        end.first
        if processor
          processor.get_converter(attachment_file, options, engine).process
        else
          raise "Unknown attachment #{attachment}"
        end
        processor = nil
      end
    end
  end
end
