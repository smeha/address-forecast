require "net/http"
require "json"

class GeonamesService
  Error = Class.new(StandardError)
  REQUEST_TIMEOUT = 5

  def self.coordinates_for(zip_code)
    new(zip_code).coordinates
  end

  def initialize(zip_code)
    @zip_code = zip_code
  end

  def coordinates
    postal = fetch.dig("postalcodes", 0)
    raise Error, "ZIP code '#{@zip_code}' not found" unless postal

    { lat: postal["lat"].to_f.round(4), lng: postal["lng"].to_f.round(4) }
  end

  private

  def fetch
    uri = URI("#{ENV.fetch("GEONAMES_API_URL")}/postalCodeLookupJSON" \
              "?postalcode=#{@zip_code}&country=USA&username=#{ENV.fetch("GEONAMES_USERNAME")}")
    response = http_get(uri)
    raise Error, "GeoNames returned HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue JSON::ParserError
    raise Error, "GeoNames returned an invalid JSON response"
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, SystemCallError => e
    raise Error, "Could not connect to GeoNames: #{e.message}"
  end

  def http_get(uri)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: REQUEST_TIMEOUT, read_timeout: REQUEST_TIMEOUT) do |http|
      http.get(uri.request_uri)
    end
  end
end
