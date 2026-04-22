require "net/http"
require "json"

# Encapsulates weather.gov access. Resolves the forecast grid URL from
# coordinates, parses forecast periods, and returns current, high, and low
# temperatures expected by the Forecast model.
#
# weather.gov is a public API — no key required.
class WeatherService
  Error = Class.new(StandardError)
  BASE_URL = "https://api.weather.gov"
  MAX_REDIRECTS = 3
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

    # Collect all periods that overlap today (daytime + nighttime) to derive the daily high and low across both entries.
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
    points_uri = URI("#{BASE_URL}/points/#{@lat},#{@lng}")
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

  def http_get(uri, redirect_count = 0)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT) do |http|
      response = http.request(request_for(uri))
      return follow_redirect(uri, response, redirect_count) if response.is_a?(Net::HTTPRedirection)

      response
    end
  end

  def request_for(uri)
    request = Net::HTTP::Get.new(uri.request_uri)
    request["Accept"] = "application/geo+json, application/json"
    request["User-Agent"] = "address-forecast"
    request
  end

  def follow_redirect(uri, response, redirect_count)
    raise Error, "weather.gov returned too many redirects" if redirect_count >= MAX_REDIRECTS

    location = response["Location"]
    return response if location.blank?

    http_get(URI.join(uri.to_s, location), redirect_count + 1)
  end
end
