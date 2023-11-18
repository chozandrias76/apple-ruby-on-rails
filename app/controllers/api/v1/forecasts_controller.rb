# frozen_string_literal: true

module Api
  module V1
    class ForecastsController < ApplicationController
      before_action :search_latitude_longitude, only: %i[search]
      rescue_from StandardError, with: :handle_standard_error

      # GET /forecasts/search
      # GET /forecasts/search.json
      def search
        @forecast = ForecastSearch.new(latitude: @latitude, longitude: @longitude, zip_code: @zip_code).perform
        # update_search_headers must be called after ForecastSearch for this @zip_code
        # otherwise the TTL will be -2
        update_search_headers(@zip_code)
      end

      private

      def handle_standard_error(exception)
        # Handle general standard errors
        logger.error "#{self.class.name}: #{exception.message}"
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

      # Use callbacks to share common setup or constraints between actions.
      def search_latitude_longitude
        @latitude, @longitude, @zip_code = AddressSearch.new(forecast_params[:address]).perform
      end

      def update_search_headers(zip_code)
        remaining_ttl = Weather.redis.ttl("forecast_search:#{zip_code}")
        response.headers['Cache-Control'] = "public, max-age=#{remaining_ttl}" if remaining_ttl.positive?
        response.headers['Date'] = Time.now.utc.to_formatted_s(:rfc822)
      end

      # Only allow a list of trusted parameters through.
      def forecast_params
        params.require(:forecast).permit(:address)
      end
    end
  end
end
