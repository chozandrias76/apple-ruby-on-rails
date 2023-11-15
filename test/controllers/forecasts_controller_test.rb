require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @forecast_id = rand(100).floor
    stub_request(:get, /https:\/\/geocode.maps.co\/search\?q.*/).to_return(status: 200, body: "[]", headers: {})
  end

  test "should search forecast" do
    get forecasts_search_url(@forecast_id), as: :json
    assert_response :success
  end
end
