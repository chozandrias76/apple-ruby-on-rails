require 'test_helper'

class ForecastPartialTest < ActionView::TestCase
  setup do
    @forecast = Forecast.new(zip_code: '12345', current_temperature: '67')
  end

  test 'the jbuilder partial produces correct JSON' do
    # Act
    json = JSON.parse(render(template: 'api/v1/forecasts/_forecast', locals: { forecast: @forecast }, formats: [:json]))

    # Assert
    assert_equal @forecast.zip_code, json['data']['id']
    assert_equal @forecast.current_temperature, json['data']['attributes']['current_temperature']
    assert_equal %r{/api/v1/forecasts/search.json?forecast%5Bzip_code%5D=12345/}, json['links']['self']
  end
end
