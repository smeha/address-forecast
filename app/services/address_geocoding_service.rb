class AddressGeocodingService
  Error = Class.new(StandardError)

  def self.lookup(address)
    new(address).lookup
  end

  def initialize(address)
    @address = address
  end

  def lookup
    result = Array(Geocoder.search(@address)).first
    raise Error, "Address could not be found" unless result

    zip_code = extract_zip_code(result)
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

  def extract_zip_code(result)
    result.data.to_h.dig("address", "postcode").to_s[/\d{5}/]
  end

  def coordinate_for(value, name)
    Float(value)
  rescue ArgumentError, TypeError
    raise Error, "Address did not resolve to a valid #{name}"
  end
end
