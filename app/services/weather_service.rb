require "net/http"
require "json"

class WeatherService
  Error = Class.new(StandardError)

  def self.fetch_forecast(lat:, lng:)
    new(lat: lat, lng: lng).forecast
  end

  def initialize(lat:, lng:)
    @lat = lat
    @lng = lng
  end

  def forecast
    periods = fetch_periods
    raise Error, "No forecast periods returned from weather.gov" if periods.blank?

    today = Time.now.strftime("%m/%d/%y")
    today_temps = periods.select do |period|
      Time.parse(period["startTime"]).strftime("%m/%d/%y") == today ||
        Time.parse(period["endTime"]).strftime("%m/%d/%y") == today
    end.map { |period| period["temperature"] }

    {
      current_temp: periods.first["temperature"],
      high_temp: today_temps.max || periods.first["temperature"],
      low_temp: today_temps.min || periods.first["temperature"]
    }
  end

  private

  def fetch_periods
    points_uri = URI("#{ENV.fetch("WEATHER_GOV_API_URL")}/points/#{@lat},#{@lng}")
    points_response = Net::HTTP.get_response(points_uri)
    forecast_url = JSON.parse(points_response.body).dig("properties", "forecast")
    raise Error, "Could not resolve forecast URL from weather.gov" unless forecast_url

    forecast_response = Net::HTTP.get_response(URI(forecast_url))
    JSON.parse(forecast_response.body).dig("properties", "periods") || []
  end
end
