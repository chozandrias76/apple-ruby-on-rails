json.data do
  json.type 'forecast'
  json.id forecast.zip_code
  json.attributes do
    json.current_temperature forecast.current_temperature
  end
  json.links do
    json.self forecasts_search_url(zip_code: forecast.zip_code, format: :json)
  end
end