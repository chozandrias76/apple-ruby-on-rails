# frozen_string_literal: true

json.data do
  json.type 'forecast'
  json.id forecast.zip_code
  json.attributes do
    json.current_temperature forecast.current_temperature
    json.day_ahead_high forecast.day_ahead_high
    json.day_ahead_low forecast.day_ahead_low
  end
  json.links do
    json.self api_v1_forecasts_search_url(forecast: { zip_code: forecast.zip_code }, format: :json)
  end
end
