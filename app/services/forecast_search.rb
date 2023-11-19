# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

class ForecastSearch
  # The external URI used for finding forecasts.
  INITIAL_EXTERNAL_URI = 'https://api.weather.gov/points/'

  # @param latitude [String] a float like string representing a location's latitude
  # @param longitude [String] a float like string representing a location's longitude
  # @param zip_code [String] the zip code used to initialize a cache key
  def initialize(latitude:, longitude:, zip_code:)
    raise ArgumentError, "#{self.class.name}: Cannot create with nil arguments" unless latitude && longitude && zip_code

    @latitude = format('%<num>0.4f', num: latitude)
    @longitude = format('%<num>0.4f', num: longitude)
    @forecast = Forecast.new(zip_code:)
    @cache_key = "#{self.class.name.underscore}:#{zip_code}"
    @initial_request_uri = "#{INITIAL_EXTERNAL_URI}#{@latitude},#{@longitude}"
  end

  # Fetches cross origin and provides a Forecast
  # for a given location at the current time
  # @note the provider gives a forecastHourly link, which is the second request target URI
  # @note the provider yields an array of hourly forecast periods, of which, the first should match the current hour
  # @return [Forecast] A new or cached forecast with up-to-date data
  def perform
    return @forecast if cached_result

    response = point_weather
    unless response.is_a?(Net::HTTPSuccess)

      log_unsuccessful_response
      return @forecast
    end

    update_forecast_and_cache(response)

    log_successful_response
    @forecast
  end

  private

  def update_forecast_and_cache(response)
    forecast_hourly_request = forecast_hourly_request(response.body)
    complete_response = fetch_hourly_forecast(forecast_hourly_request)
    @forecast.current_temperature =
      JSON.parse(complete_response.body)['properties']['periods'].first['temperature']

    Weather.redis.set(@cache_key, @forecast.to_json, ex: Constants::DEFAULT_CACHE_DURATION_SECONDS)
  end

  def log_successful_response
    Rails.logger.info "#{self.class.name}: Providing a newly cached forecast"
  end

  def log_unsuccessful_response
    Rails.logger.debug "#{self.class.name}: Response did not return a successful status code"
  end

  def cached_result
    return unless Weather.redis.get(@cache_key)

    @forecast = Forecast.new(**JSON.parse(Weather.redis.get(@cache_key)).symbolize_keys)
  end

  def forecast_hourly_request(response_body)
    JSON.parse(response_body)['properties']['forecastHourly']
  end

  def point_weather
    Net::HTTP.get_response(
      URI.parse(@initial_request_uri)
    )
  end

  # @param forecast_hourly_request [String] example:
  # "https://api.weather.gov/gridpoints/SEW/125,71/forecast/hourly"
  def fetch_hourly_forecast(forecast_hourly_request)
    Net::HTTP.get_response(
      URI.parse(forecast_hourly_request)
    )
  end
end
