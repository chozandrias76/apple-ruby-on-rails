require 'net/http'
require 'uri'
require 'json'

class ForecastSearch
  INITIAL_EXTERNAL_URI = "https://api.weather.gov/points/".freeze

  # @param latitude [String] a float like string representing a location's latitude
  # @param longitude [String] a float like string representing a location's longitude
  # @param zip_code [String] the zip code used to initialize a cache key
  def initialize(latitude:, longitude:, zip_code:)
    @latitude = format('%<num>0.4f', num: latitude)
    @longitude = format('%<num>0.4f', num: longitude)
    @forecast = Forecast.new({"zip_code" => zip_code})
    @cache_key = "#{self.class.name.underscore}:#{zip_code}"
    @initial_request_uri = "#{INITIAL_EXTERNAL_URI}#{@latitude},#{@longitude}"
  end

  # Fetches cross origin and provides the temperature in F
  # for a given location at the current time
  # @note the provider gives a forecastHourly link, which is the second
  # request target URI
  # @note the provider yields an array of hourly forecast periods, of which, the first
  # should match the current hour
  # @return [Integer] The value of temperature in F
  def perform
    cached_result = $redis.get(@cache_key)
    if cached_result
      Rails.logger.debug "#{self.class.name}: Providing cached result"
      return Forecast.new(JSON.parse(cached_result))
    end

    response = fetch_point_weather
    unless response.is_a?(Net::HTTPSuccess)
      
      Rails.logger.debug "#{self.class.name}: Response did not return a successful status code"
      return @forecast
    end

    initial_response = get_forecast_hourly_request(response.body)
    complete_response = fetch_hourly_forecast(initial_response)
    set_forecast_current_temperature(complete_response.body)

    $redis.set(@cache_key, @forecast.to_json, ex: Constants::DEFAULT_CACHE_DURATION_SECONDS)
    
    Rails.logger.info "#{self.class.name}: Providing a newly cached latitude and longitude"
    @forecast
  end

  private

  def get_forecast_hourly_request(response_body)
    JSON.parse(response_body)["properties"]["forecastHourly"]
  end

  def fetch_point_weather
    Net::HTTP.get_response(
      URI.parse(@initial_request_uri)
    )
  end

  def set_forecast_current_temperature(response_body)
    @forecast.current_temperature = 
    JSON.parse(response_body)["properties"]["periods"].first["temperature"]
  end

  # @param forecast_hourly_request [String] example:
  # "https://api.weather.gov/gridpoints/SEW/125,71/forecast/hourly"
  def fetch_hourly_forecast(forecast_hourly_request)
    Net::HTTP.get_response(
      URI.parse(forecast_hourly_request)
    )
  end
end