class ForecastsController < ApplicationController
  before_action :set_forecast, only: %i[ show ]

  # GET /forecasts/1
  # GET /forecasts/1.json
  def show
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_forecast
      @forecast =  OpenStruct.new() 
    end

    # Only allow a list of trusted parameters through.
    def forecast_params
      params.fetch(:forecast, {})
    end
end
