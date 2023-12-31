# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# AddressSearch is a utility class for geocoding an address to obtain its latitude and longitude.
# It fetches data from a cross-origin provider and caches results in Redis for efficient reuse.
#
# The class is designed to handle requests with rate limiting in mind, as the provider limits to
# two requests per second.
#
# @example
#   search = AddressSearch.new(address: "1600 Amphitheatre Parkway, Mountain View, CA, 94043")
#   # OR search = AddressSearch.new(zip_code: "94043")
#   lat_long = search.perform
#   # => ["37.422388", "-122.084188", "94043"]
#
class AddressSearch
  # The external URI used for geocoding requests.
  EXTERNAL_URI = 'https://geocode.maps.co/search'
  # Regular expression to match a ZIP code within an address string.
  # There is no perfect expression for matching generic strings,
  # but this variant matches with the least valid exceptions.
  ZIP_MATCH = /\d{5}(-\d{4})?\b/

  # An extension of StandardError to ensure it can be captured separately and that the message contains the class name
  # this class is a child to.
  class ZipMismatchException < StandardError
    def initialize(message)
      message = "AddressSearch: #{message}"
      super
    end
  end

  # Initializes a new instance of AddressSearch.
  #
  # @param address [String] an unencoded string of the full address.
  # @param zip_code [String, nil] an optional ZIP code to use for the search instead of the address.
  def initialize(address:, zip_code: nil)
    @address = address
    @zip_code = zip_code
  end

  # Fetches cross origin and provides address information
  # @note the cross-origin provider limits two requests per second
  # @return [[String, String, String]] Representations of the address' latitude, longitude and zip-code
  def perform
    return cached_result if cached_result

    response = fetch_latitude_longitude
    unless response.is_a?(Net::HTTPSuccess)
      log_unsuccessful_response
      return []
    end

    latitude_longitude_and_zip = latitude_longitude_zip_and_update_cache(response)

    log_successful_response
    latitude_longitude_and_zip
  end

  private

  def latitude_longitude_zip_and_update_cache(response)
    latitude_longitude_and_zip = latitude_longitude_and_zip(response)

    Weather.redis.set(cache_key, latitude_longitude_and_zip.to_json, ex: Constants::DEFAULT_CACHE_DURATION_SECONDS)
    latitude_longitude_and_zip
  end

  def log_successful_response
    Rails.logger.info "#{self.class.name}: Providing a newly cached latitude and longitude"
  end

  def log_unsuccessful_response
    Rails.logger.error "#{self.class.name}: Response did not return a successful status code"
  end

  def cached_result
    return unless Weather.redis.get(cache_key).present? # Allows for re-fetching

    parsed_response = JSON.parse(Weather.redis.get(cache_key))
    return if parsed_response.empty? # Allows for re-fetching

    parsed_response
  end

  def latitude_longitude_and_zip(response)
    processed_response = JSON.parse(response.body)[0]

    if !processed_response.present? || processed_response.empty?
      log_empty_or_falsy_body
      return []
    end
    [processed_response['lat'], processed_response['lon'], @zip_code || matched_zip_code!]
  end

  def log_empty_or_falsy_body
    Rails.logger.error "#{self.class.name}: Response contained an empty or falsy body"
  end

  def cache_key
    "#{self.class.name.underscore}:#{@zip_code || matched_zip_code!}"
  end

  def matched_zip_code!
    match = @address.match(ZIP_MATCH)
    raise ZipMismatchException, 'Cannot process without zip-code within address' unless match

    (match || [])[0]
  end

  def fetch_latitude_longitude
    uri = URI.parse(EXTERNAL_URI)
    uri.query = URI.encode_www_form(q: @zip_code || @address)
    Net::HTTP.get_response(uri)
  end
end
