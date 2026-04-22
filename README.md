# Address Forecast application
## Tech Stack
* Ruby (v3.4.8)
* Rails (v8.1)
* PostgreSQL (v18)
* Bundler (4.0.10)
* RSpec-Rails (v8.0)
* Geocoder (v1.8)
* RuboCop (via rubocop-rails-omakase + rubocop-performance + rubocop-rspec)

## How to run locally
### Prerequisites
- Ruby 3.4.8 (`rbenv install 3.4.8`)
- PostgreSQL running locally (`brew services start postgresql`)
- Bundler

### Install dependencies
```bash
bundle install
```

### Setup database
```bash
rails db:create
rails db:migrate
```

### Run the project
```bash
rails s
```

### Usage
* In terminal(command line) type: `rails s`
* Open in the browser URL: http://127.0.0.1:3000/
* Enter a street address or 5-digit US ZIP code in the forecast lookup form. The application resolves the input to latitude, longitude, and ZIP code, retrieves weather data for that location, and stores the forecast by ZIP code for cache reuse.

## Linting, tests, type checking and audits
### RuboCop
```bash
rubocop
rubocop -a  # auto-fix safe offenses
```

## Run test cases
```bash
rspec
```

## Application audits
```bash
brakeman --no-pager
bundler-audit
```

## APIs Used
### Geocoder
Geocoder gem is used for resolving a street address or ZIP code to latitude, longitude, and ZIP code.

The app currently configures Geocoder to use Nominatim in `config/initializers/geocoder.rb`. For production use, consider a provider with a commercial license and higher request limits.

### https://www.weather.gov/
Weather.gov is used for getting the forecast via latitude and longitude.

Example: https://api.weather.gov/points/{latitude},{longitude}

## Object Decomposition
### `Forecast`
Active Record model for cached forecast data. It owns ZIP code validation, the 30-minute cache freshness rule, and the query scopes used to display recently updated forecasts.

### `ForecastsController`
Coordinates the web request flow. It validates lookup input presence, asks `AddressGeocodingService` to resolve the input, uses ZIP code as the cache key, and delegates weather retrieval to `WeatherService`.

### `AddressGeocodingService`
Encapsulates Geocoder provider details. It converts a user-entered address or ZIP code into a small normalized hash containing `lat`, `lng`, and `zip_code`, and raises a service-specific error for controller-safe handling.

### `WeatherService`
Encapsulates weather.gov access. It resolves the weather.gov grid forecast URL, parses forecast periods, and returns the current, high, and low temperatures expected by the `Forecast` model.

## Design Notes
* The application accepts full addresses and 5-digit US ZIP codes, but intentionally caches by ZIP code to match the requirement and avoid duplicate cache entries for "equivalent" addresses.
* Service objects isolate external API details from Rails controllers and models.
* External service failures are converted to application-specific errors so the UI can present useful feedback without exposing low-level exceptions.
* Request and service specs cover successful lookup, cache reuse, stale cache refresh, geocoding failures, weather.gov failures, and model validation.

## Scalability Considerations
* The database enforces one cached forecast per ZIP code with a unique index.
* The current provider is suitable for a small exercise. A production deployment should use a geocoding provider with explicit rate limits, monitoring and retry guidance.
* For higher traffic, the forecast cache could move from database to Redis while retaining ZIP code as the cache key.
* Background refresh could be added later, for example in Sidekiq, if stale forecasts should be updated asynchronously instead of during user requests.

## Initial Requirements
### Requirements:
* Must be done in Ruby on Rails
* Accept an address as input
* Retrieve forecast data for the given address. This should include, at minimum, the current temperature (Bonus points - Retrieve high/low and/or extended forecast)
* Display the requested forecast details to the user
* Cache the forecast details for 30 minutes for all subsequent requests by zip codes. Display indicator if result is pulled from cache.
### Assumptions
* This project is open to interpretation
* Functionality is a priority over form
