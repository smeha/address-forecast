require "net/http"
require "json"

class GeonamesService
  Error = Class.new(StandardError)

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
    response = Net::HTTP.get_response(uri)
    JSON.parse(response.body)
  end
end
