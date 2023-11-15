require 'net/http'
require 'uri'
require 'json'

# Provides data from geocode.maps.co
class AddressSearch
  EXTERNAL_URI = "https://geocode.maps.co/search".freeze
  ZIP_MATCH = /(?<!^)\b\d{5}(-\d{4})?\b/.freeze

  # @param address [String] an unencoded string of the full address
  def initialize(address)
    @address = address
  end

  # Fetches cross origin and provides latitude and longitude
  # @note the cross-origin provider limits two requests per second
  # @return [[String, String]] Float-like string representations of
  # the address' latitude and longitude
  def perform
    cached_result = $redis.get(cache_key)
    if cached_result
      Rails.logger.debug "#{self.class.name}: Providing cached result"
      return JSON.parse(cached_result) 
    end
  
    response = make_api_call
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.debug "#{self.class.name}: Response did not return a successful status code"
      return []
    end

    complete_response = processed_response(response)

    $redis.set(cache_key, complete_response.to_json, ex: 1800)
    
    Rails.logger.info "#{self.class.name}: Providing a newly cached latitude and longitude"
    complete_response
  end

  private

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
    [processed_response["lat"], processed_response["lon"], zip_code]
  end

  def cache_key
    key = "#{self.class.name.underscore}:#{zip_code}"
    return key
  end

  def zip_code
    match = ZIP_MATCH.match(@address)
    (match || [])[0]
  end

  def make_api_call
    uri = URI.parse(EXTERNAL_URI)
    uri.query = URI.encode_www_form(q: @address)
    Net::HTTP.get_response(uri)
  end
end