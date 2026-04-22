require "net/http"
require "json"

class WeatherService
  Error = Class.new(StandardError)
  REQUEST_TIMEOUT = 5

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
    forecast_url = fetch_json(points_uri, "weather.gov points API").dig("properties", "forecast")
    raise Error, "Could not resolve forecast URL from weather.gov" unless forecast_url

    fetch_json(URI(forecast_url), "weather.gov forecast API").dig("properties", "periods") || []
  end

  def fetch_json(uri, source)
    response = http_get(uri)
    raise Error, "#{source} returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "#{source} returned an invalid JSON response"
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError => e
    raise Error, "Could not connect to #{source}: #{e.message}"
  end

  def http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT) do |http|
      http.get(uri.request_uri)
    end
  end
end
