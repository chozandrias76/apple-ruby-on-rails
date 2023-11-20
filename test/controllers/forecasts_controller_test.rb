# frozen_string_literal: true

require 'test_helper'

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @address_search_mock = Minitest::Mock.new
    @forecast_search_mock = Minitest::Mock.new

    # Define what the mock's perform method should return
    @address_search_mock.expect :perform, ['123.45', '-678.91', '98115']
    @forecast_search_mock.expect :perform, Forecast.new(zip_code: '12345')

    @original_logger_level = Rails.logger.level
    Rails.logger.level = Logger::ERROR
  end

  teardown do
    Rails.logger.level = @original_logger_level
  end

  test 'it should provide a success status code' do
    AddressSearch.stub :new, @address_search_mock do
      ForecastSearch.stub :new, @forecast_search_mock do
        get api_v1_forecasts_search_url, params: { address: 'Fake+St+Seattle+Washington+98115' }, as: :json
      end
    end

    assert_response :success
  end

  test 'it should include cache control in headers for a successful response' do
    AddressSearch.stub :new, @address_search_mock do
      ForecastSearch.stub :new, @forecast_search_mock do
        get api_v1_forecasts_search_url, params: { address: 'Fake+St+Seattle+Washington+98115' }, as: :json
      end
    end

    assert_includes @response.headers, 'Cache-Control'
    assert_includes @response.headers, 'Date'
  end

  test 'it provides a JSON API compliant error json when a StandardError occurs' do
    address_search_error_mock = Minitest::Mock.new
    address_search_error_mock.expect :perform, nil do
      raise StandardError, 'Standard error occurred'
    end

    AddressSearch.stub :new, address_search_error_mock do
      get api_v1_forecasts_search_url, params: { address: 'Fake+St+Seattle+Washington+98115' }, as: :json
    end

    assert_response :internal_server_error
    json_response = JSON.parse(@response.body)

    assert json_response['errors'].is_a?(Array)
    assert_equal '500', json_response['errors'].first['status']
    assert_equal 'Internal Server Error', json_response['errors'].first['title']
    assert_equal 'An unexpected error occurred.', json_response['errors'].first['detail']
  end
end
