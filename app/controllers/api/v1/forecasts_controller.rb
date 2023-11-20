# frozen_string_literal: true

module Api
  module V1
    # The ForecastsController is responsible for handling API requests
    # related to weather forecasts. It provides an endpoint to search for
    # weather forecasts based on a given address or ZIP code, returning forecast
    # data such as temperature and weather conditions.
    #
    # This controller uses AddressSearch to convert an address or ZIP code into
    # latitude and longitude, which are then used by ForecastSearch to fetch
    # the actual forecast data. The controller also manages caching of forecast data
    # and ensures that the response headers are appropriately set for caching.
    #
    # @example GET /forecasts/search
    #   # Request format:
    #   {
    #     "forecast": {
    #       "address": "123 Main St, Anytown, USA 12345",
    #     }
    #   }
    #
    #   # Response format:
    #   {
    #     "data":
    #       {
    #         "type":"forecast",
    #         "id":"12345",
    #         "attributes":{
    #           "current_temperature":"45.0",
    #           "day_ahead_high":"53.0",
    #           "day_ahead_low":"29.0"
    #         },
    #         "links":{
    #           "self":"http://localhost:3000/api/v1/forecasts/search.json?forecast%5Bzip_code%5D=12345"}}}
    #
    #   # Headers:
    #   cache-control: max-age=1298, public # time to live in seconds, 1800 indicates a fresh response
    #   date: Mon, 20 Nov 2023 00:38:15 +0000 # date-time of response
    class ForecastsController < ApplicationController
      before_action :search_latitude_longitude, only: %i[search]
      after_action :update_search_headers, only: %i[search]
      rescue_from StandardError, with: :handle_standard_error

      # GET /forecasts/search
      # GET /forecasts/search.json
      def search
        @forecast = ForecastSearch.new(latitude: @latitude, longitude: @longitude, zip_code: @zip_code).perform
      end

      private

      def handle_standard_error(exception)
        # Handle general standard errors
        logger.error "#{self.class.name}: #{exception.message}"
        logger.error exception.backtrace.join("\n") if Rails.env.development?
        render_standard_error_json
      end

      def render_standard_error_json
        render json: {
          errors: [
            {
              status: '500',
              title: 'Internal Server Error',
              detail: 'An unexpected error occurred.'
            }
          ]
        }, status: :internal_server_error
      end

      def search_latitude_longitude
        @latitude, @longitude, @zip_code =
          AddressSearch.new(
            address: forecast_params[:address],
            zip_code: forecast_params[:zip_code]
          ).perform
      end

      def update_search_headers
        # update_search_headers must be called after ForecastSearch for this @zip_code
        # otherwise the TTL will be -2
        remaining_ttl = Weather.redis.ttl("forecast_search:#{@zip_code}")
        response.headers['Cache-Control'] = "public, max-age=#{remaining_ttl}" if remaining_ttl.positive?
        response.headers['Date'] = Time.now.utc.to_formatted_s(:rfc822)
      end

      def forecast_params
        params.require(:forecast).permit(:address, :zip_code)
      end
    end
  end
end
