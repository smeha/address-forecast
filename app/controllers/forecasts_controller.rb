require 'uri'
require 'net/http'

class ForecastsController < ApplicationController
  before_action :set_forecast, only: %i[ show edit update destroy ]

  # GET /forecasts or /forecasts.json
  def index
    @forecasts = Forecast.all
  end

  # GET /forecasts/1 or /forecasts/1.json
  def show
  end

  # GET /forecasts/new
  def new
    @forecast = Forecast.new
  end

  # GET /forecasts/1/edit
  def edit
  end

  # POST /forecasts or /forecasts.json
  def create
    @forecastExist = Forecast.find_by_zip_code(forecast_params[:zip_code])
    timeSinceCache = 30.minutes.ago.localtime

    # API Calls with the ZIP Code param
    # LOGIC BELLOW ONLY WHEN Forcast doesn't exist or need to be updated
    if forecast_params[:zip_code] && ((@forecastExist && @forecastExist.updated_at.localtime < timeSinceCache) || (!@forecastExist))
      uri = URI("#{ENV['GEONAMES_API_URL']}/postalCodeLookupJSON?postalcode=#{forecast_params[:zip_code]}&country=USA&username=#{ENV['GEONAMES_USERNAME']}")
      res = Net::HTTP.get_response(uri)
      dataLatLong = JSON.parse(res.body)

      # Round to 4 decimal digits per API specifications
      uri = URI("#{ENV['WEATHER_GOV_API_URL']}/points/#{"%.4f" % dataLatLong['postalcodes'][0]['lat']},#{"%.4f" % dataLatLong['postalcodes'][0]['lng']}")
      res = Net::HTTP.get_response(uri)
      dataForecastProperties = JSON.parse(res.body)

      uri = URI(dataForecastProperties['properties']['forecast'])
      res = Net::HTTP.get_response(uri)
      dataForecast = JSON.parse(res.body)

      dataForLowHighTemp = []

      nowDate = Time.now.strftime('%m/%d/%y')
      dataForecast['properties']['periods'].each do |period|
        periodDateStart = Time.parse(period['startTime']).strftime('%m/%d/%y')
        periodDateEnd =  Time.parse(period['endTime']).strftime('%m/%d/%y')
        if periodDateStart == nowDate || periodDateEnd == nowDate
          dataForLowHighTemp << period['temperature']
        end
      end

      params[:forecast][:current_temp] = dataForecast['properties']['periods'][0]['temperature']
      params[:forecast][:low_temp] = dataForLowHighTemp.min
      params[:forecast][:high_temp] = dataForLowHighTemp.max
    end

    if(@forecastExist && @forecastExist.updated_at.localtime < timeSinceCache)
      @forecast = @forecastExist
      respond_to do |format|
        if @forecast.update(forecast_params)
          @forecast.touch
          format.html { redirect_to forecast_url(@forecast), notice: "Forecast Cache was successfully updated." }
          format.json { render :show, status: :ok, location: @forecast }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @forecast.errors, status: :unprocessable_entity }
        end
      end
    elsif @forecastExist
      @forecast = @forecastExist
      respond_to do |format|
        format.html { redirect_to forecast_url(@forecast), notice: "Forecast was already cached less than 30min ago." }
        format.json { render :show, status: :created, location: @forecast }
      end
    else
      @forecast = Forecast.new(forecast_params)
      respond_to do |format|
        if @forecast.save
          format.html { redirect_to forecast_url(@forecast), notice: "Forecast was successfully cached for the first time." }
          format.json { render :show, status: :created, location: @forecast }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @forecast.errors, status: :unprocessable_entity }
        end
      end
    end
  end

  # PATCH/PUT /forecasts/1 or /forecasts/1.json
  def update
    respond_to do |format|
      if @forecast.update(forecast_params)
        format.html { redirect_to forecast_url(@forecast), notice: "Forecast was successfully updated." }
        format.json { render :show, status: :ok, location: @forecast }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @forecast.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /forecasts/1 or /forecasts/1.json
  def destroy
    @forecast.destroy!

    respond_to do |format|
      format.html { redirect_to forecasts_url, notice: "Forecast was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_forecast
      @forecast = Forecast.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def forecast_params
      params.require(:forecast).permit(:zip_code, :current_temp, :high_temp, :low_temp)
    end
end
