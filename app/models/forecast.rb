# frozen_string_literal: true

class Forecast
  def initialize(args = { 'zip_code' => BigDecimal::NAN, 'current_temperature' => BigDecimal::NAN })
    @current_temperature = args['current_temperature']
    @zip_code = args['zip_code']
  end

  attr_writer :current_temperature, :zip_code

  attr_accessor :current_temperature, :zip_code
end
