require 'sprockets'

module Alula
  class Manifest < Sprockets::Manifest
    attr_accessor :tracker
    
    def assets_with_tracking
      @_assets ||= AssetTracker.new assets_without_tracking, @tracker
    end
    alias_method :assets_without_tracking, :assets
    alias_method :assets, :assets_with_tracking
    
    def used_assets
      @_assets.used
    end
    
    def clear_tracking
      @tracker = nil
    end
    
    private
    class AssetTracker
      def initialize(hash, tracker)
        @hash = hash
        @used = []
        @tracker = tracker
      end
    
      def used
        @used.uniq
      end
    
      def [](key)
        @used << @hash[key]
        @hash[key]
      end
    
      def []=(key, value)
        @hash[key] = value
        @tracker.inc if @tracker
      end
    end
  end
end
