class AddressGeocodingService
  Error = Class.new(StandardError)

  def self.lookup(address)
    new(address).lookup
  end

  def initialize(address)
    @address = address
  end

  def lookup
    zip_code_input = Forecast.valid_zip_code?(@address)
    result = Array(Geocoder.search(search_query)).first
    raise Error, "Address could not be found" unless result

    zip_code = zip_code_input ? @address : extract_zip_code(result)
    raise Error, "Address did not resolve to a valid US ZIP code" unless Forecast.valid_zip_code?(zip_code)

    {
      lat: coordinate_for(result.latitude, "latitude"),
      lng: coordinate_for(result.longitude, "longitude"),
      zip_code: zip_code
    }
  rescue Geocoder::Error => e
    raise Error, "Could not geocode address: #{e.message}"
  end

  private

  def search_query
    Forecast.valid_zip_code?(@address) ? "#{@address}, USA" : @address
  end

  def extract_zip_code(result)
    result.data.to_h.dig("address", "postcode").to_s[/\d{5}/]
  end

  def coordinate_for(value, name)
    Float(value)
  rescue ArgumentError, TypeError
    raise Error, "Address did not resolve to a valid #{name}"
  end
end
