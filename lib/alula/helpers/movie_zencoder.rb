require 'aws-sdk'
require 'zencoder'
require 'mini_exiftool'
require 'progressbar'
require 'digest/md5'
require 'base64'

module Alula
  module Helpers
    class Movie_Zencoder < MovieHelper
      def initialize(asset, options)
        super
        
        @video_info = MiniExiftool.new asset
        
        Zencoder.api_key = options["videos"]["zencoder"]["token"]
        @s3 = AWS::S3.new({
          :access_key_id     => @options["videos"]["zencoder"]["key_id"],
          :secret_access_key => @options["videos"]["zencoder"]["access_key"]
        })        
      end
      
      def encode(variants, thumbnail)
        return if variants.empty? and !thumbnail
        
        unless asset_exists_in_bucket
          upload_asset_to_bucket
        end
        
        job_description = {
          :input => "s3://#{@bucket.name}/#{@object.key}", :outputs => []
        }
        variants.each do |variant, opts|
          format = (File.extname(variant).empty? ? variant : File.extname(variant)[1..-1])
          output = { :label => "#{@name}#{File.extname(variant).empty? ? "." : ""}#{variant}", :format => format }
          output = output.deep_merge(opts)
          output[:device_profile] = output.delete(:profile) if output.key?(:profile)
          output[:thumbnails] = { :label => "#{@name}.png", :number => 1, :size => @options["videos"]["thumbnails"] } if thumbnail
          
          job_description[:outputs] << output
        end
        # Thumbnail generation
        if job_description[:outputs].empty?
          job_description[:outputs] << {:thumbnails => { :label => "#{@name}.png", :number => 1, :size => @options["videos"]["thumbnails"] } }
        end
        
        # Encode outputs
        response = Zencoder::Job.create(job_description)
        return nil if response.code != "201"
      
        job_id = response.body['id']
        pb = ProgressBar.new "Encoding", 100
        while (%w{pending waiting processing}.include?((job = Zencoder::Job.progress(job_id)).body['state']))
          pb.set(job.body['progress'].to_f)
          sleep(1)
        end
        pb.finish
      
        # Processing done, successful?
        job = Zencoder::Job.details(job_id)
        if job.body['job']['state'] != "finished"
          return nil
        end
        
        # Download assets
        unless variants.empty?
          puts "==> Downloading encoded videos"
        
          job.body['job']['output_media_files'].each_with_index do |output, idx|
            output_io = File.open(File.join(@image_path, output['label']), "w")
          
            pbar = nil
            open(output['url'], {
              :content_length_proc => lambda {|t|
                if t && 0 < t
                  pbar = ProgressBar.new "(%i/%i)" % [idx + 1, job.body['job']['output_media_files'].count ], t
                  pbar.file_transfer_mode
                end
              },
              :progress_proc => lambda {|s|
                pbar.set s if pbar
              }
            }) do |io|
              output_io.write(io.read)
            end
            pbar.finish if pbar
          end
        end
        if thumbnail
          # Download thumbnail
          open(job.body['job']['thumbnails'].first['url']) do |io|
            File.open(File.join(@thumbnail_path, job.body['job']['thumbnails'].first['group_label']), "w") do |tn_io|
              tn_io.write(io.read)
            end
          end
        end
      end
      
      private
      def asset_exists_in_bucket
        @bucket = @s3.buckets[@options["videos"]["zencoder"]["bucket"]]
        unless @bucket.exists?
          @bucket = @s3.buckets.create(@options["videos"]["zencoder"]["bucket"])
        end
      
        folder = @bucket.objects["#{@asset_path}/"]
        unless folder.exists?
          folder = @bucket.objects["#{@asset_path}/"].write(nil)
        end
      
        object_name = File.join(@asset_path, "#{@name}.#{@ext}")
        @object = @bucket.objects[object_name]
        return @object.exists?
      end
      
      def upload_asset_to_bucket
        puts "--> Uploading file, this might take a while, please be patient."
        
        min_chunk_size = 5 * 1024 * 1024  # S3 Multipart minimum chunk size (%Mb)
        @object.multipart_upload do |upload|
          io = File.open(@asset)
          
          if io.size > 2 * min_chunk_size
            pb = ProgressBar.new "#{@name}", io.size
            pb.file_transfer_mode
          end
          
          parts = []

          bufsize = (io.size > 2 * min_chunk_size) ? min_chunk_size : io.size
          while buf = io.read(bufsize)
            md5 = Digest::MD5.base64digest(buf)
            
            part = upload.add_part(buf)
            parts << part

            pb.set(io.pos) if pb
            if (io.size - (io.pos + bufsize)) < bufsize
              bufsize = (io.size - io.pos) if (io.size - io.pos) > 0
            end
          end
          
          upload.complete(parts)
          
          pb.finish if pb
        end
        
        # Give Zencoder permissions to read our input video
        @object.acl.change do |acl|
          acl.grant(:read).to(:canonical_user_id => '6c8583d84664a381db0c6af0e79b285ede571885fbe768e7ea50e5d3760597dd')
        end
      end
    end
  end
end
