Geocoder.configure(
  lookup: :nominatim,
  timeout: 5,
  units: :mi,
  http_headers: {
    "User-Agent" => "address-forecast"
  }
)
