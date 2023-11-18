# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Provides data from geocode.maps.co
class AddressSearch
  EXTERNAL_URI = 'https://geocode.maps.co/search'
  ZIP_MATCH = /(?<!^)\b\d{5}(-\d{4})?\b/

  # @param address [String] an unencoded string of the full address
  def initialize(address)
    @address = address
  end

  # Fetches cross origin and provides latitude and longitude
  # @note the cross-origin provider limits two requests per second
  # @return [[String, String]] Float-like string representations of
  # the address' latitude and longitude
  def perform
    return cached_result if cached_result

    response = fetch_latitude_longitude
    unless response.is_a?(Net::HTTPSuccess)
      log_unsuccessful_response
      return []
    end

    latitude_and_longitude = latitude_longitude_and_update_cache(response)

    log_successful_response
    latitude_and_longitude
  end

  private

  def latitude_longitude_and_update_cache(response)
    latitude_and_longitude = processed_response(response)

    Weather.redis.set(cache_key, latitude_and_longitude.to_json, ex: Constants::DEFAULT_CACHE_DURATION_SECONDS)
    latitude_and_longitude
  end

  def log_successful_response
    Rails.logger.info "#{self.class.name}: Providing a newly cached latitude and longitude"
  end

  def log_unsuccessful_response
    Rails.logger.debug "#{self.class.name}: Response did not return a successful status code"
  end

  def cached_result
    return unless Weather.redis.get(cache_key)

    JSON.parse(Weather.redis.get(cache_key))
  end

  def processed_response(response)
    processed_response = JSON.parse(response.body)[0]

    unless processed_response
      Rails.logger.debug "#{self.class.name}: Response contained a falsy body"
      return []
    end
    if processed_response == []
      Rails.logger.debug "#{self.class.name}: Response contained an empty body"
      return []
    end
    [processed_response['lat'], processed_response['lon'], zip_code]
  end

  def cache_key
    "#{self.class.name.underscore}:#{zip_code}"
  end

  def zip_code
    match = ZIP_MATCH.match(@address)
    (match || [])[0]
  end

  def fetch_latitude_longitude
    uri = URI.parse(EXTERNAL_URI)
    uri.query = URI.encode_www_form(q: @address)
    Net::HTTP.get_response(uri)
  end
end
