# Address Forecast application
## Tech Stack
- Ruby (v3.4.8)
- Rails (v8.1)
- PostgreSQL (v18)
- Bundler (4.0.10)
- RSpec-Rails (v8.0)
- RuboCop (via rubocop-rails-omakase + rubocop-performance + rubocop-rspec)

## How to run locally
### Install dependencies
```bash
bundle install
npm install
```

### Setup database
```bash
rails db:create
rails db:migrate
rails db:seed
```

### Setup environment variables
```bash
cp .env.example .env
```

### Run the project
In separate terminals:
```bash
rails s
```

### Usage
In terminal(command line) type: `rails s`

Open in the browser URL: http://127.0.0.1:3000/

## Tests
In terminal(command line) type:  `rails test`

## APIs Used
### https://www.geonames.org/
For decoding ZIP Code to lat/long

Example: http://api.geonames.org/postalCodeLookupJSON?postalcode=%ZIPCODE%&country=USA&username=%GEONAMESUSERNAME%

Unused(!) example for only current forecast: http://api.geonames.org/findNearByWeatherJSON?lat=%LAT%&lng=%LONG%&username=%GEONAMESUSERNAME%

### https://www.weather.gov/
For getting the forecast via lat/long

Example: https://api.weather.gov/points/{latitude},{longitude}

## Initial Requirments
### Requirements:
* Must be done in Ruby on Rails
* Accept an address as input
* Retrieve forecast data for the given address. This should include, at minimum, the current temperature (Bonus points - Retrieve high/low and/or extended forecast)
* Display the requested forecast details to the user
* Cache the forecast details for 30 minutes for all subsequent requests by zip codes. Display indicator if result is pulled from cache.
### Assumptions
* This project is open to interpretation
* Functionality is a priority over form

