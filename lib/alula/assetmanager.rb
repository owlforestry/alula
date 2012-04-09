# require 'RMagick'
# require 'aws-sdk'
# require 'zencoder'
require 'alula/helpers/imagehelper'
require 'alula/helpers/moviehelper'
require 'progressbar'
require 'digest/md5'
require 'base64'

module Alula
  class AssetManager
    def initialize(asset_path, options)
      # @asset_path = asset_path
      @options = options
      @options[:asset_path] = asset_path
    end
    
    def process(asset, options = {})
      options = @options.deep_merge(options)
      
      # Resolve our asset type
      ext = File.extname(asset)[1..-1] || ""
      
      if Alula::Helpers::ImageHelper.identify(asset)
        [:image, Alula::Helpers::ImageHelper.process(asset, options)]
        # [:image, process_image(asset, options)]
      elsif Alula::Helpers::MovieHelper.identify(asset)
        [:movie, Alula::Helpers::MovieHelper.process(asset, options)]
      else
        puts "Unknown asset type #{ext} for #{asset}"
        false
      end
    end
  end
end
