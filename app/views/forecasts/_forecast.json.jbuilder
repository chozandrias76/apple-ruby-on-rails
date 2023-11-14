json.extract! forecast, :id, :created_at, :updated_at
json.url forecasts_search_url(forecast, format: :json)
