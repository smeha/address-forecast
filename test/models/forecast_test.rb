require "test_helper"

class ForecastTest < ActiveSupport::TestCase
  setup do
    @forecast = forecasts(:one)
  end

  test "zip_code should not be blank" do
    @forecast.zip_code = ''
    assert_not @forecast.valid?
  end
end
