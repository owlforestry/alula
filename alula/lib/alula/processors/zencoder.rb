require 'alula/processors/video'
require 'aws-sdk'
require 'zencoder'

module Alula
  class Zencoder < VideoProcessor
    # Register mimetypes
    mimetype /^video\//
    
    def self.available?(options)
      options.has_key?("token") and options.has_key?("key_id") and options.has_key?("access_key")
    end
    
    def initialize(item, opts)
      super
      
      @@lock.synchronize do
        ::Zencoder.api_key = options.token
        @s3 = ::AWS::S3.new({
          :access_key_id     => options.key_id,
          :secret_access_key => options.access_key,
        })
      end
    end
    
    def cleanup
      super
      
      @s3 = nil
      @bucket = nil
      @object = nil
      ::Zencoder.api_key = nil
    end
    
    def encode(variants, thumbnails)
      return if variants.empty? and thumbnails.empty?
      
      @variants = variants
      @thumbnails = thumbnails
      
      # Upload attachment to S3 bucket
      upload_item unless item_uploaded
      
      # Create encoding profiles
      job = {input: "s3://#{@bucket.name}/#{@object.key}", outputs: [], test: !!self.site.config.testing}
      
      profiles.each { |name, profile| job[:outputs] << profile }
      
      job = zencoder_encode(job)
      success = zencoder_download(job)
    end
    
    private
    def item_uploaded
      @bucket ||= @s3.buckets[self.site.config.attachments.zencoder.bucket]
      unless @bucket.exists?
        @bucket = @s3.buckets.create(self.site.config.attachments.zencoder.bucket)
      end
      
      folder = @bucket.objects["#{File.dirname(item.name)}/"]
      unless folder.exists?
        folder = @bucket.objects["#{File.dirname(item.name)}/"].write(nil)
      end
      
      @object = @bucket.objects[item.name]
      return @object.exists?
    end
    
    def upload_item
      # Fetch upload lock to guarantee that we're onlyones to upload
      @@upload.synchronize do
        self.site.progress.create :upload, title: "Uploading #{item.name}", total: File.size(item.filepath)
        self.site.progress.set_file_transfer(:upload)

        min_chunk_size = 5 * 1024 * 1024  # S3 minimum chunk size (5Mb)
        @object.multipart_upload do |upload|
          io = File.open(item.filepath)
          
          parts = []
          
          bufsize = (io.size > 2 * min_chunk_size) ? min_chunk_size : io.size
          while buf = io.read(bufsize)
            md5 = Digest::MD5.base64digest(buf)
            
            part = upload.add_part(buf)
            parts << part
            
            self.site.progress.set(:upload, io.pos)
            if (io.size - (io.pos + bufsize)) < bufsize
              bufsize = (io.size - io.pos) if (io.size - io.pos) > 0
            end
          end
          
          upload.complete(parts)
        end
        
        self.site.progress.finish(:upload)
        
        # Give Zencoder rights to read file
        @object.acl.change do |acl|
          acl.grant(:read).to(:canonical_user_id => '6c8583d84664a381db0c6af0e79b285ede571885fbe768e7ea50e5d3760597dd')
        end
      end
    end
    
    def zencoder_encode(job)
      File.open('cache/job.yml', 'w') {|io| io.write job.to_yaml}
      response = ::Zencoder::Job.create(job)
      return false if response.code != "201"
      
      job_id = response.body["id"]
      self.site.progress.create "encode-#{job_id}", title: "Encoding #{item.name}", total: 100
      while (%w{pending waiting processing}.include?((job = ::Zencoder::Job.progress(job_id)).body['state']))
        self.site.progress.set("encode-#{job_id}", job.body['progress'].to_f)
        sleep(1)
      end
      self.site.progress.finish "encode-#{job_id}"
      
      job = ::Zencoder::Job.details(job_id)
      if job.body['job']['state'] != "finished"
        return false
      end
      return job
    end
    
    def zencoder_download(job)
      @@download.synchronize do
        unless @variants.empty?
          job.body['job']['output_media_files'].each_with_index do |output, idx|
            output_name = profiles[output['label']][:filename]
            output_io = File.open(output_name, 'w')
        
            open(output['url'], {
              :content_length_proc => lambda {|t|
                if t && 0 < t
                  self.site.progress.create output['label'],
                    title: "Downloading (%i/%i)" % [idx + 1, job.body['job']['output_media_files'].count],
                    total: t
                  self.site.progress.set_file_transfer(output['label'])
                end
              },
              :progress_proc => lambda {|s|
                  self.site.progress.set(output['label'], s)
              }
            }) do |io|
              output_io.write(io.read)
            end
            self.site.progress.finish(output['label'])
          end
        end
        
        if job.body['job']['thumbnails']
          # Download thumbnails
          job.body['job']['thumbnails'].each do |tn|
            output_file = @thumbnails[tn['group_label']][:output]

            open(tn['url']) { |i| File.open(output_file, 'w') {|o| o.write(i.read) } }
          end
        end
        
        return true
      end
    end
    
    def profiles
      @profiles ||= begin
        profiles = Hash[@variants.collect { |variant, opts|
          profile = {
            label: variant,
            filename: opts[:output],
            format: opts[:format],
            size: opts[:size],
          }
          if opts[:mobile]
            profile[:device_profile] = opts[:hires] ? "mobile/advanced" : "mobile/baseline"
          end
          [variant, profile]
        }]
        
        unless profiles.empty?
          profiles[profiles.keys.first][:thumbnails] = thumbnail_profiles
        end
        if profiles.empty? and !thumbnail_profiles.empty?
          profiles = {thumbnails: { thumbnails: thumbnail_profiles }}
        end
        profiles
      end
    end
    
    def thumbnail_profiles
      @thumbnail_profiles ||= @thumbnails.collect do |label, tn|
        {
          label: tn[:label],
          number: 1,
          size: tn[:size],
        }
      end
    end
  end
end

Alula::AttachmentProcessor.register('zencoder', Alula::Zencoder)
