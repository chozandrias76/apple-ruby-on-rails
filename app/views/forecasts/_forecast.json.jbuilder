json.extract! forecast, :latitude, :longitude
json.url forecasts_search_url(forecast, format: :json)
