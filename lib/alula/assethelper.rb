require 'RMagick'
require 'aws-sdk'
require 'zencoder'
require 'mini_exiftool'
require 'progressbar'
require 'digest/md5'
require 'base64'

module Alula
  class AssetHelper
    IMAGES = %w{jpeg jpg png gif}
    MOVIES = %w{mp4 mov}
    
    def initialize(asset_path, options)
      @asset_path = asset_path
      @options = options
      
      # Connect to cloud, videos
      if @options["videos"]["encode"] == "zencoder"
        # Zencoder
        Zencoder.api_key = @options["videos"]["zencoder"]["token"]
        
        # Input/Output support
        # @s3 = Fog::Storage.new({
        #   :provider => 'AWS',
        #   :aws_access_key_id => @options["videos"]["zencoder"]["key_id"],
        #   :aws_secret_access_key => @options["videos"]["zencoder"]["access_key"],
        #   # :region => 
        # })
        # @s3.sync_clock
        @s3 = AWS::S3.new({
          :access_key_id     => @options["videos"]["zencoder"]["key_id"],
          :secret_access_key => @options["videos"]["zencoder"]["access_key"]
        })
      end
    end
    
    def process(asset, options)
      options = @options.deep_merge(options)
      
      # Resolve our asset type
      ext = File.extname(asset)[1..-1] || ""
      
      if IMAGES.include?(ext.downcase)
        [:image, process_image(asset, options)]
      elsif MOVIES.include?(ext.downcase)
        [:movie, process_movie(asset, options)]
      else
        puts "Unknown asset type #{ext} for #{asset}"
        false
      end
    end
    
    private
    def process_image(asset, options)
      ext = File.extname(asset)[1..-1].downcase
      name = case options[:keepcase]
      when true
        File.basename(asset, File.extname(asset))
      else
        File.basename(asset, File.extname(asset)).to_url
      end
      generated = []
      
      # Resolve size for new photo
      width, height = case options[:type]
      when :attachment
      when :original
        options["images"]["size"].split("x").collect {|i| i.to_i }
      when :thumbnail
        options["images"]["thumbnails"].split("x").collect {|i| i.to_i }
      end
      
      file_path = case options[:type]
      when :attachment
      when :original
        File.join("attachments", "_generated", "images", @asset_path)
      when :thumbnail
        File.join("attachments", "_generated", "thumbnails", @asset_path)
      end
      # Create output path
      FileUtils.mkdir_p(file_path)
      
      # Copy asset to originals
      if [:attachement, :original].include?(options[:type]) and !File.exists?(File.join("attachments", "originals", @asset_path, "#{name}.#{ext}"))
        FileUtils.mkdir_p File.join("attachments", "originals", @asset_path)
        FileUtils.cp asset, File.join("attachments", "originals", @asset_path, "#{name}.#{ext}")
      end
      
      # Create normal photo
      image = Magick::Image.read(asset).first
      image_width, image_height = image.columns, image.rows
      
      resized = image.resize_to_fit(width, height)
      resized.write(File.join(file_path, "#{name}.#{ext}"))
      generated << File.join(@asset_path, "#{name}.#{ext}")
      
      # Generate retina if required
      if (options["images"]["retina"] and (image_width > width * 2) or (image_height > height * 2))
        retina = image.resize_to_fit(width * 2, height * 2)
        resized.write(File.join(file_path, "#{name}_2x.#{ext}"))
        generated << File.join(@asset_path, "#{name}_2x.#{ext}")
      end
      
      return generated
    end

    def process_movie(asset, options)
      # Detect our basename
      ext = File.extname(asset)[1..-1].downcase
      name = case options[:keepcase]
      when true
        File.basename(asset, File.extname(asset))
      else
        File.basename(asset, File.extname(asset)).to_url
      end
      
      # Collect transformed videos here
      generated = []
      
      file_path = case options[:type]
      when :attachment
        File.join("attachments", "_generated", "images", @asset_path)
      when :thumbnail
        File.join("attachments", "_generated", "thumbnails", @asset_path)
      end
      images_path = File.join("attachments", "_generated", "images", @asset_path)
      thumbnails_path = File.join("attachments", "_generated", "thumbnails", @asset_path)
      
      # Create output path
      FileUtils.mkdir_p(file_path)
      FileUtils.mkdir_p(thumbnails_path)
            
      # Copy asset to originals
      if options[:type] == :attachment and !File.exists?(File.join("attachments", "originals", @asset_path, "#{name}.#{ext}"))
        FileUtils.mkdir_p File.join("attachments", "originals", @asset_path)
        FileUtils.cp asset, File.join("attachments", "originals", @asset_path, "#{name}.#{ext}")
      end
      
      # Check that video does not exists in storage
      bucket = @s3.buckets[@options["videos"]["zencoder"]["in_bucket"]]
      unless bucket.exists?
        bucket = @s3.buckets.create(@options["videos"]["zencoder"]["in_bucket"])
      end
      
      folder = bucket.objects["#{@asset_path}/"]
      unless folder.exists?
        folder = bucket.objects["#{@asset_path}/"].write(nil)
      end
      
      object_name = File.join(@asset_path, "#{name}.#{ext}")
      object = bucket.objects[object_name]
      unless object.exists?
        puts "--> Uploading file"
        
        min_chunk_size = 5 * 1024 * 1024  # S3 Multipart minimum chunk size (%Mb)
        object.multipart_upload do |upload|
          io = File.open(asset)
          
          if io.size > 2 * min_chunk_size
            pb = ProgressBar.new "#{name}", io.size
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
      end
      
      puts "==> Encode video"
      # Make sure zencoder has rights to read

      object.acl.change do |acl|
        acl.grant(:read).to(:canonical_user_id => '6c8583d84664a381db0c6af0e79b285ede571885fbe768e7ea50e5d3760597dd')
      end
      
      # Submitting for encoding
      opts = { :input => "s3://#{bucket.name}/#{object.key}", :outputs => [] }
      # Get original size
      video_info = MiniExiftool.new asset
      
      size_hd = @options["videos"]["size"].split("x")
      size_sd = "640x360".split("x")
      tn_size = @options["videos"]["thumbnails"].split("x")
      # Check if we have portrait video
      if video_info.rotation == 90 or video_info.rotation == 270
        size_hd.reverse!
        size_sd.reverse!
        tn_Size.reverse!
      end
      size_hd = size_hd.join("x")
      size_sd = size_sd.join("x")
      tn_size = tn_size.join("x")
      
      # Have HD size?
      if video_info.imagewidth >= 1280 and video_info.imageheight >= 720
        opts[:outputs] << { :label => "#{name}-hd.mp4",        :format => "mp4", :size => size_hd }
        opts[:outputs] << { :label => "#{name}-mobile-hd.mp4", :format => "mp4", :size => size_hd, :device_profile => "mobile/advanced" }
      end
      opts[:outputs] << { :label => "#{name}-mobile.mp4", :format => "mp4",  :size => size_sd, :device_profile => "mobile/baseline" }
      opts[:outputs] << { :label => "#{name}.mp4",        :format => "mp4",  :size => size_sd }
      opts[:outputs] << { :label => "#{name}.webm",       :format => "webm", :size => size_sd }
      opts[:outputs] << { :label => "#{name}.ogg",        :format => "ogg",  :size => size_sd }
      # Request thumbnail
      opts[:outputs].collect {|o| o[:thumbnails] = { :number => 1, :label => "#{name}.png", :size => tn_size } }
      
      # Encode outputs
      response = Zencoder::Job.create(opts)
      return nil if response.code != "201"
      
      job_id = response.body['id']
      pb = ProgressBar.new "Encoding", 100
      while (%w{pending waiting processing}.include?((job = Zencoder::Job.progress(job_id)).body['state']))
        pb.set(job.body['progress'].to_f)
        sleep(1)
      end
      pb.finish
      
      # Processing done and finished?
      job = Zencoder::Job.details(job_id)
      # require 'pry';binding.pry
      if job.body['job']['state'] != "finished"
        return nil
      end
      
      # Download assets
      puts "==> Downloading encoded videos"
      job.body['job']['output_media_files'].each_with_index do |output, idx|
        output_io = File.open(File.join(file_path, output['label']), "w")
          
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
      # Download thumbnail
      open(job.body['job']['thumbnails'].first['url']) do |io|
        File.open(File.join(thumbnails_path, job.body['job']['thumbnails'].first['group_label']), "w") do |tn_io|
          tn_io.write(io.read)
        end
      end
      
      return File.join(@asset_path, "#{name}.mp4")
    end
  end
end
