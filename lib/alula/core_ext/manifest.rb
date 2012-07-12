require 'sprockets/manifest'

module Alula
  class Manifest < Sprockets::Manifest
    attr_accessor :progress
    
    def assets
      @__assets ||= super
      @_assets ||= AssetTracker.new @__assets, @progress
    end
    
    private
    class AssetTracker
      def initialize(hash, progress_callback)
        @hash = hash
        @used = []
        @progress_cb = progress_callback
      end
      
      def used; @used.uniq; end
      
      def [](key)
        @used << @hash[key]
        @hash[key]
      end
      
      def []=(key, value)
        @hash[key] = value
        @progress_cb.call if @progress_cb
      end
    end
  end
end
