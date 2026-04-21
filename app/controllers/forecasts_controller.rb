class ForecastsController < ApplicationController
  before_action :set_forecast, only: %i[show destroy]

  def index
    @forecasts = Forecast.by_recently_updated
  end

  def show
  end

  def new
    @forecast = Forecast.new
  end

  def create
    zip_code = forecast_params[:zip_code]
    existing = Forecast.find_by(zip_code: zip_code)

    if existing&.fresh?
      redirect_to forecast_url(existing), notice: "Forecast was already cached less than 30 minutes ago."
      return
    end

    weather_data = fetch_weather_data(zip_code)

    if weather_data.nil?
      @forecast = Forecast.new(zip_code: zip_code)
      render :new, status: :unprocessable_content
      return
    end

    if existing
      existing.update!(weather_data)
      redirect_to forecast_url(existing), notice: "Forecast cache was successfully updated."
    else
      @forecast = Forecast.new(weather_data.merge(zip_code: zip_code))
      if @forecast.save
        redirect_to forecast_url(@forecast), notice: "Forecast was successfully cached."
      else
        render :new, status: :unprocessable_content
      end
    end
  end

  def destroy
    @forecast.destroy!
    redirect_to forecasts_url, notice: "Forecast was successfully removed."
  end

  private

  def set_forecast
    @forecast = Forecast.find(params[:id])
  end

  def forecast_params
    params.require(:forecast).permit(:zip_code)
  end

  def fetch_weather_data(zip_code)
    coords = GeonamesService.coordinates_for(zip_code)
    WeatherService.fetch_forecast(lat: coords[:lat], lng: coords[:lng])
  rescue GeonamesService::Error, WeatherService::Error => e
    flash.now[:alert] = e.message
    nil
  end
end
