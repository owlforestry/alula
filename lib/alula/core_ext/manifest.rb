require 'sprockets/manifest'

module Alula
  class Manifest < Sprockets::Manifest
    attr_accessor :progress
    
    def assets_with_tracking
      @_assets ||= AssetTracker.new assets_without_tracking, @progress
    end
    alias_method :assets_without_tracking, :assets
    alias_method :assets, :assets_with_tracking
    
    private
    class AssetTracker
      def initialize(hash, progress_callback)
        @hash = hash
        @progress_cb = progress_callback
      end
      
      def [](key)
        @hash[key]
      end
      
      def []=(key, value)
        @hash[key] = value
        @progress_cb.call if @progress_cb
      end
    end
  end
end
