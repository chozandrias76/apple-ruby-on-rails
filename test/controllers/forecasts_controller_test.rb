require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @forecast_id = rand(100).floor
  end

  test "should show forecast" do
    get forecasts_search_url(@forecast_id), as: :json
    assert_response :success
  end
end
