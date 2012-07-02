require 'simplecov'
SimpleCov.start do
  # Skip support (from ActiveSupport)
  add_filter "lib/alula/support/deep_merge.rb"
  
  add_group "Gem", "lib/"
  add_group "Tests", "test/"
end

require 'turn/autorun'
require "minitest/autorun"

Turn.config.format = :outline