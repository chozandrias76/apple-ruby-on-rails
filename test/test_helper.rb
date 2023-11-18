# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'
require 'minitest/autorun'
require 'mock_redis'

# Configure WebMock
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Replace Redis with MockRedis in tests
    def setup
      $redis = MockRedis.new
    end
  end
end
