# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# The ForecastSearch class is responsible for fetching weather forecast data
# for a given location using the National Weather Service API.
# It initializes with latitude, longitude, and zip code, and provides
# methods to perform the forecast search and handle responses.
#
# The class handles fetching data from two different endpoints:
# the initial point data based on latitude and longitude, and
# the hourly forecast data. It also integrates caching of forecast data
# using Redis to reduce unnecessary external requests.
#
# @example
#   forecast_search = ForecastSearch.new(latitude: "47.6062", longitude: "-122.3321", zip_code: "98101")
#   forecast = forecast_search.perform
#   puts forecast.current_temperature
#   # 51
#
class ForecastSearch
  # The external URI used for finding forecasts.
  INITIAL_EXTERNAL_URI = 'https://api.weather.gov/points/'

  # @param latitude [String] a float like string representing a location's latitude
  # @param longitude [String] a float like string representing a location's longitude
  # @param zip_code [String] the zip code used to initialize a cache key
  # @raise [ArgumentError] If any of the arguments are nil.
  def initialize(latitude:, longitude:, zip_code:)
    unless latitude && longitude && zip_code
      raise ArgumentError,
            "#{self.class.name}: Cannot create with nil arguments \
            \n lat: #{latitude}, lon: #{longitude}, zip: #{zip_code}"
    end

    @latitude = format('%<num>0.4f', num: latitude)
    @longitude = format('%<num>0.4f', num: longitude)
    @forecast = Forecast.new(zip_code:)
    @cache_key = "#{self.class.name.underscore}:#{zip_code}"
    @initial_request_uri = "#{INITIAL_EXTERNAL_URI}#{@latitude},#{@longitude}"
  end

  # Performs the operation to fetch and return an up-to-date Forecast object.
  # This method first checks for a cached forecast before making any external requests.
  # If the cache is empty or outdated, it fetches new data and updates the cache.
  #
  # @note the provider gives a forecastHourly link, which is the second request target URI
  # @note the provider yields an array of hourly forecast periods, of which, the first should match the current hour
  # @return [Forecast] A new or cached forecast with up-to-date data
  def perform
    return @forecast if cached_result

    metadata_response = fetch_point_metadata
    unless metadata_response.is_a?(Net::HTTPSuccess)

      log_unsuccessful_response
      return @forecast
    end

    update_forecast_and_cache(metadata_response)

    log_successful_response
    @forecast
  end

  private

  def update_forecast_and_cache(response)
    forecast_hourly_request = forecast_hourly_request(response.body)
    complete_response = fetch_hourly_forecast(forecast_hourly_request)
    parsed_periods = JSON.parse(complete_response.body)['properties']['periods']
    apply_parsed_periods_data(parsed_periods)

    Weather.redis.set(@cache_key, @forecast.to_json, ex: Constants::DEFAULT_CACHE_DURATION_SECONDS)
  end

  def apply_parsed_periods_data(parsed_periods)
    @forecast.current_temperature =
      BigDecimal(parsed_periods.first['temperature'])
    day_ahead_high, day_ahead_low = day_ahead_high_and_low(parsed_periods)

    @forecast.day_ahead_high = day_ahead_high
    @forecast.day_ahead_low = day_ahead_low
  end

  def day_ahead_high_and_low(parsed_periods)
    day_ahead_high = nil
    day_ahead_low = nil

    parsed_periods.each do |period|
      current_temperature = BigDecimal(period['temperature'])
      day_ahead_high = current_temperature if day_ahead_high.nil? || day_ahead_high < current_temperature
      day_ahead_low = current_temperature if day_ahead_low.nil? || day_ahead_low > current_temperature
    end
    [day_ahead_high, day_ahead_low]
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

  # "https://api.weather.gov/points/12.3,-4.56"
  def fetch_point_metadata
    Net::HTTP.get_response(
      URI.parse(@initial_request_uri)
    )
  end

  # @param forecast_hourly_request [String] Usually provided by the initial request's response
  # @example fetch_hourly_forecast("https://api.weather.gov/gridpoints/SEW/125,71/forecast/hourly")
  def fetch_hourly_forecast(forecast_hourly_request)
    Net::HTTP.get_response(
      URI.parse(forecast_hourly_request)
    )
  end
end
