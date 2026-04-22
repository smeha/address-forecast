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
    address = forecast_params[:address].to_s.strip

    if address.blank?
      @forecast = Forecast.new(address: address)
      @forecast.errors.add(:address, :blank)
      render :new, status: :unprocessable_content
      return
    end

    location = geocode_address(address)
    return if performed?

    zip_code = location.fetch(:zip_code)
    existing = Forecast.find_by(zip_code: zip_code)

    if existing&.fresh?
      redirect_to forecast_url(existing), notice: "Forecast was pulled from cache."
      return
    end

    weather_data = fetch_weather_data(location)

    if weather_data.nil?
      @forecast = Forecast.new(address: address, zip_code: zip_code)
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
    params.require(:forecast).permit(:address)
  end

  def geocode_address(address)
    AddressGeocodingService.lookup(address)
  rescue AddressGeocodingService::Error => e
    @forecast = Forecast.new(address: address)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_content
    nil
  end

  def fetch_weather_data(location)
    WeatherService.fetch_forecast(lat: location.fetch(:lat), lng: location.fetch(:lng))
  rescue WeatherService::Error => e
    flash.now[:alert] = e.message
    nil
  end
end
