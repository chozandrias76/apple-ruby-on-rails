# frozen_string_literal: true

class Forecast
  def initialize(zip_code: BigDecimal::NAN, current_temperature: BigDecimal::NAN)
    @current_temperature = current_temperature
    @zip_code = zip_code
  end

  def to_h
    instance_variables.each_with_object({}) do |var, hash|
      hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
    end
  end

  attr_accessor :current_temperature, :zip_code
end
