# frozen_string_literal: true

require 'test_helper'

class ForecastPartialTest < ActionView::TestCase
  setup do
    @forecast = Forecast.new(
      zip_code: '12345', current_temperature: '67',
      day_ahead_high: '123',
      day_ahead_low: '0.123'
    )
  end

  test 'the jbuilder partial produces correct JSON' do
    # Act
    json = JSON.parse(render(template: 'api/v1/forecasts/_forecast', locals: { forecast: @forecast }, formats: [:json]))

    # Assert
    assert_equal @forecast.zip_code, json['data']['id']
    assert_equal @forecast.current_temperature, json['data']['attributes']['current_temperature']
    assert_equal @forecast.day_ahead_high, json['data']['attributes']['day_ahead_high']
    assert_equal @forecast.day_ahead_low, json['data']['attributes']['day_ahead_low']
    assert_equal 'http://test.host/api/v1/forecasts/search.json?forecast%5Bzip_code%5D=12345',
                 json['data']['links']['self']
  end
end
