module Alula
  class DummyProcessor < Processor
    
    def process
      super
        
      asset_name = self.attachments.asset_name(item.name)
      output = File.join(self.site.storage.path(:cache, "attachments"), asset_name)
      # Make sure our directory exists
      output_dir = self.site.storage.path(:cache, "attachments", File.dirname(asset_name))
      
      # Skip processing if output already exists...
      unless File.exists?(output)
        # Just simply copy attachement
        FileUtils.cp(item.filepath, output)
      end
      
      # Cleanup ourself
      cleanup
    end
  end
end

Alula::AttachmentProcessor.register('dummy', Alula::DummyProcessor)
