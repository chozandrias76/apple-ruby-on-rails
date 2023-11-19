# frozen_string_literal: true

json.data do
  json.type 'forecast'
  json.id forecast.zip_code
  json.attributes do
    json.current_temperature forecast.current_temperature
  end
  json.links do
    json.self api_v1_forecasts_search_url(forecast: { zip_code: forecast.zip_code }, format: :json)
  end
end
