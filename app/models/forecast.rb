# frozen_string_literal: true

# The Forecast class represents weather forecast data for a specific location
# identified by a ZIP code. It holds information about the current temperature,
# as well as the day's future high and low temperatures.
#
# Each temperature attribute is represented using BigDecimal for precision.
# The class provides a method to
# convert its data into a hash, allowing for easy serialization or further manipulation.
#
# @example Creating a new Forecast instance
#   forecast = Forecast.new(zip_code: "90210",
#                           current_temperature: BigDecimal("70.0"),
#                           day_ahead_high: BigDecimal("75.2"),
#                           day_ahead_low: BigDecimal("65.3"))
#
# @example Converting Forecast instance to a hash
#   forecast_hash = forecast.to_h
#   # => { :zip_code => "90210", :current_temperature => BigDecimal("70.0"),
#   #      :day_ahead_high => BigDecimal("75.2"), :day_ahead_low => BigDecimal("65.3") }
class Forecast
  # Initializes a new Forecast instance with weather data.
  #
  # @param zip_code [String] the ZIP code of the location, required by default.
  # @param current_temperature [BigDecimal] the current temperature, defaulting to NaN if not provided.
  # @param day_ahead_high [BigDecimal] the next day's high temperature, defaulting to NaN if not provided.
  # @param day_ahead_low [BigDecimal] the next day's low temperature, defaulting to NaN if not provided.
  def initialize(zip_code:, current_temperature: BigDecimal::NAN, day_ahead_high: BigDecimal::NAN,
                 day_ahead_low: BigDecimal::NAN)
    @current_temperature = current_temperature
    @day_ahead_high = day_ahead_high
    @day_ahead_low = day_ahead_low
    @zip_code = zip_code
  end

  # Converts the Forecast instance data into a hash.
  #
  # @return [Hash] a hash representation of the Forecast instance.
  def to_h
    instance_variables.each_with_object({}) do |var, hash|
      hash[var.to_s.delete('@').to_sym] = instance_variable_get(var)
    end
  end

  attr_accessor :current_temperature, :day_ahead_high, :day_ahead_low, :zip_code
end
