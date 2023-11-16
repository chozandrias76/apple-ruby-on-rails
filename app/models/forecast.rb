class Forecast
  def initialize(args = {"zip_code" => BigDecimal::NAN, "current_temperature" => BigDecimal::NAN})
    @current_temperature = args["current_temperature"]
    @zip_code = args["zip_code"]
  end

  def current_temperature=(new_temperature)
    @current_temperature = new_temperature
  end

  def zip_code=(new_zip_code)
    @zip_code = new_zip_code
  end

  attr_accessor :current_temperature, :zip_code
end