# frozen_string_literal: true

module Api
  module V1
    class ForecastsController < ApplicationController
      before_action :search_forecast, only: %i[search]

      # GET /forecasts/search
      # GET /forecasts/search.json
      def search; end

      private

      # Use callbacks to share common setup or constraints between actions.
      def search_forecast
        latitude, longitude, zip_code = AddressSearch.new(forecast_params[:address]).perform
        @forecast = ForecastSearch.new(latitude:, longitude:, zip_code:).perform
        update_search_headers(zip_code)
        @forecast
      end

      def update_search_headers(zip_code)
        remaining_ttl = Weather.redis.ttl("forecast_search:#{zip_code}")
        response.headers['Cache-Control'] = "public, max-age=#{remaining_ttl}"
        response.headers['Date'] = Time.now.utc.to_formatted_s(:rfc822)
      end

      # Only allow a list of trusted parameters through.
      def forecast_params
        params
      end
    end
  end
end
