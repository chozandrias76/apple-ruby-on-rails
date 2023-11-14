require 'net/http'
require 'uri'
require 'json'

# Provides data from geocode.maps.co
class AddressSearch
  EXTERNAL_URI = "https://geocode.maps.co/search".freeze

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
    return JSON.parse(cached_result) if cached_result
  
    response = make_api_call

    return [] unless response.is_a?(Net::HTTPSuccess)

    complete_response = JSON.parse(response.body)[0]
    $redis.set(cache_key, complete_response.to_json, ex: 1800)
    
    latitude, longitude = [complete_response.try("lat"), complete_response.try("lon")]
  end

  private

  def cache_key
    "#{self.class.name.underscore}:#{@address}"
  end

  def make_api_call
    uri = URI.parse(EXTERNAL_URI)
    uri.query = URI.encode_www_form(q: @address)
    Net::HTTP.get_response(uri)
  end
end