require 'minitest/autorun'
require 'bigdecimal'

class ForecastTest < Minitest::Test
  def setup
    @zip_code = BigDecimal('90210')
    @current_temperature = BigDecimal('70.0')
    @day_ahead_high = BigDecimal('75.2')
    @day_ahead_low = BigDecimal('65.3')
    @forecast = Forecast.new(zip_code: @zip_code,
                             current_temperature: @current_temperature,
                             day_ahead_high: @day_ahead_high,
                             day_ahead_low: @day_ahead_low)
  end

  def test_initialization
    assert_equal @zip_code, @forecast.zip_code
    assert_equal @current_temperature, @forecast.current_temperature
    assert_equal @day_ahead_high, @forecast.day_ahead_high
    assert_equal @day_ahead_low, @forecast.day_ahead_low
  end

  def test_to_h
    expected_hash = {
      zip_code: @zip_code,
      current_temperature: @current_temperature,
      day_ahead_high: @day_ahead_high,
      day_ahead_low: @day_ahead_low
    }
    assert_equal expected_hash, @forecast.to_h
  end
end
