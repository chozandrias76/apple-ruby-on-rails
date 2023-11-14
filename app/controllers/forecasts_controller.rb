class ForecastsController < ApplicationController
  before_action :search_forecast, only: %i[ search ]

  # GET /forecasts/search
  # GET /forecasts/search.json
  def search
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def search_forecast
      @forecast = OpenStruct.new() 
    end

    # Only allow a list of trusted parameters through.
    def forecast_params
      params.fetch(:forecast, {})
    end
end
