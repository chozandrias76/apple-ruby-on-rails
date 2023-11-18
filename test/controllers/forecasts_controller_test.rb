# frozen_string_literal: true

require 'test_helper'

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @address_search_mock = Minitest::Mock.new
    @forecast_search_mock = Minitest::Mock.new

    # Define what the mock's perform method should return
    @address_search_mock.expect :perform, ['123.45', '-678.91', '98115']
    @forecast_search_mock.expect :perform, Forecast.new
  end

  test 'should search forecast' do
    AddressSearch.stub :new, @address_search_mock do
      ForecastSearch.stub :new, @forecast_search_mock do
        get api_v1_forecasts_search_url({ address: nil }), as: :json
      end
    end
    assert_response :success

    @address_search_mock.verify
    @forecast_search_mock.verify
  end
end
