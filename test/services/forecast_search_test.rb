# frozen_string_literal: true

require 'test_helper'

describe ForecastSearch do # rubocop:disable Metrics/BlockLength
  before(:each) do
    @zip_code = '98115'
    latitude = '123.45'
    longitude = '-67.89'
    @forecast_search = ForecastSearch.new(latitude:, longitude:, zip_code: @zip_code)
    @expected_request_url = Regexp.new("#{ForecastSearch::INITIAL_EXTERNAL_URI}.*") # %r{https://api\.weather\.gov/points/.*}
    @mock_forecast_url = 'http://www.fake.com'

    @original_logger_level = Rails.logger.level
    Rails.logger.level = Logger::ERROR
  end

  after(:each) do
    Weather.redis.flushdb
    Rails.logger.level = @original_logger_level
  end

  it 'it should be a class with the expected name' do
    assert_equal @forecast_search.class.name, 'ForecastSearch'
  end

  it 'it should raise an ArgumentError when any of the keywords are nil' do
    err1 = assert_raises ArgumentError do
      ForecastSearch.new(latitude: nil, longitude: nil, zip_code: 1)
    end
    err2 = assert_raises ArgumentError do
      ForecastSearch.new(latitude: 1, longitude: nil, zip_code: nil)
    end
    err3 = assert_raises ArgumentError do
      ForecastSearch.new(latitude: nil, longitude: 1, zip_code: nil)
    end
    expected_error_message = 'ForecastSearch: Cannot create with nil arguments'
    assert_match expected_error_message, err1.message
    assert_match expected_error_message, err2.message
    assert_match expected_error_message, err3.message
  end

  it "it should respond to .perform with a Forecast \
      when the external requests returns successful status codes" do
    stub_request(:get, @expected_request_url).to_return(
      status: 200,
      body: "{'properties': { 'forecastHourly': '#{@mock_forecast_url}'}}".gsub("'", '"'), headers: {}
    )
    stub_request(:get, Regexp.new("#{@mock_forecast_url}.*")).to_return(
      status: 200,
      body: '{"properties": { "periods": [{"temperature": "123"}, {"temperature": "234"}, {"temperature": "12.3"}]}}', headers: {}
    )

    assert_equal Forecast.new(
      current_temperature: BigDecimal('123'),
      zip_code: @zip_code,
      day_ahead_high: BigDecimal('234'),
      day_ahead_low: BigDecimal('12.3')
    ).to_h,
                 @forecast_search.perform.to_h
  end

  it "it should respond to .perform with a default Forecast \
      when the initial external request returns an un-successful status code" do
    stub_request(:get, @expected_request_url).to_return(
      status: 500,
      body: '', headers: {}
    )

    assert_equal Forecast.new(zip_code: @zip_code).to_h, @forecast_search.perform.to_h
  end

  it "it should respond to .perform with a cached Forecast \
      when the cache matches a zip-code" do
    cached_data = <<~JSON
      {
        "zip_code": #{@zip_code}
      }
    JSON
    Weather.redis.set("forecast_search:#{@zip_code}", cached_data)

    assert_equal JSON.parse(cached_data).merge(
      current_temperature: BigDecimal::NAN,
      day_ahead_high: BigDecimal::NAN,
      day_ahead_low: BigDecimal::NAN
    ).symbolize_keys,
                 @forecast_search.perform.to_h
  end
end
