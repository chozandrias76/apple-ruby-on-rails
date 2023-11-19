# frozen_string_literal: true

require 'test_helper'

describe AddressSearch do # rubocop:disable Metrics/BlockLength
  before(:each) do
    @zip_code = '98115'
    @address = "123 Fake St. Seattle, WA, #{@zip_code}, US"
    @address_search = AddressSearch.new(@address)
    @expected_request_url = %r{https://geocode.maps.co/search\?q.*}

    @original_logger_level = Rails.logger.level
    Rails.logger.level = Logger::ERROR
  end

  after(:each) do
    Weather.redis.flushdb
    Rails.logger.level = @original_logger_level
  end

  it 'it should be a class with the expected name' do
    assert_equal @address_search.class.name, 'AddressSearch'
  end

  it "it should respond to .perform with a tuple \
      when the external request returns a successful status code" do
    stub_request(:get, @expected_request_url).to_return(status: 200,
                                                        body: '[{"lat": "123.45", "lon": "-678.91"}]', headers: {})

    assert_equal ['123.45', '-678.91', @zip_code], @address_search.perform
  end

  it "it should respond to .perform with a cached tuple \
      when the cache matches a zip-code" do
    cached_data = [1, 2, @zip_code]
    Weather.redis.set("address_search:#{@zip_code}", cached_data)

    assert_equal cached_data, @address_search.perform
  end

  it "it should respond to .perform with an empty array \
      when the external request returns an unsuccessful status code" do
    stub_request(:get, @expected_request_url).to_return(status: 500, body: '[]', headers: {})

    assert_equal [], @address_search.perform
  end

  it "it should respond to .perform with an empty array \
      when the external request returns a falsy object in the body" do
    stub_request(:get, @expected_request_url).to_return(status: 200, body: '[null]', headers: {})

    assert_equal [], @address_search.perform
  end

  it "it should respond to .perform with an empty array \
      when the external request returns an empty array in the body" do
    stub_request(:get, @expected_request_url).to_return(status: 200, body: '[]', headers: {})

    assert_equal [], @address_search.perform
  end
end
