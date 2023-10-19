require "test_helper"

class ForecastsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @forecast = forecasts(:one)
  end

  test "should get index" do
    get forecasts_url
    assert_response :success
  end

  test "should get new" do
    get new_forecast_url
    assert_response :success
  end

  test "should create forecast" do
    assert_difference("Forecast.count") do
      post forecasts_url, params: { forecast: { zip_code: '92131', current_temp:90, high_temp:90, low_temp:80 } }
    end

    assert_redirected_to forecast_url(Forecast.last)
  end

  test "should show forecast" do
    get forecast_url(@forecast)
    assert_response :success
  end

  test "should get edit" do
    get edit_forecast_url(@forecast)
    assert_response :success
  end

  test "should update forecast" do
    patch forecast_url(@forecast), params: { forecast: { current_temp:90, high_temp:90, low_temp:80 } }
    assert_redirected_to forecast_url(@forecast)
  end

  test "should destroy forecast" do
    assert_difference("Forecast.count", -1) do
      delete forecast_url(@forecast)
    end

    assert_redirected_to forecasts_url
  end
end
