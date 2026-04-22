require "rails_helper"

RSpec.describe WeatherService do
  describe ".fetch_forecast" do
    # Pin New York City for specs
    subject(:result) { described_class.fetch_forecast(lat: 40.7484, lng: -73.9967) }

    # Pin request to noon so +6h and -12h always land on the same calendar day.
    around { |example| travel_to(Time.zone.now.noon) { example.run } }

    let(:now) { Time.now }
    let(:points_body) do
      { "properties" => { "forecast" => "https://api.weather.gov/gridpoints/OKX/33,37/forecast" } }.to_json
    end

    let(:forecast_body) do
      {
        "properties" => {
          "periods" => [
            { "temperature" => 72, "startTime" => now.iso8601, "endTime" => (now + 6.hours).iso8601 },
            { "temperature" => 80, "startTime" => (now + 6.hours).iso8601, "endTime" => (now + 12.hours).iso8601 },
            { "temperature" => 58, "startTime" => (now - 12.hours).iso8601, "endTime" => now.iso8601 }
          ]
        }
      }.to_json
    end

    before do
      stub_request(:get, /weather\.gov\/points/)
        .to_return(status: 200, body: points_body, headers: { "Content-Type" => "application/json" })
      stub_request(:get, /weather\.gov\/gridpoints/)
        .to_return(status: 200, body: forecast_body, headers: { "Content-Type" => "application/json" })
    end

    it "returns current temperature from the first period" do
      expect(result[:current_temp]).to eq(72)
    end

    it "returns the high temperature for today" do
      expect(result[:high_temp]).to eq(80)
    end

    it "returns the low temperature for today" do
      expect(result[:low_temp]).to eq(58)
    end

    context "when the points API redirects to a canonical URL" do
      let(:redirected_points_url) { "https://api.weather.gov/points/40.7484,-73.9967/" }

      before do
        stub_request(:get, "https://api.weather.gov/points/40.7484,-73.9967")
          .to_return(status: 301, headers: { "Location" => redirected_points_url })
        stub_request(:get, redirected_points_url)
          .to_return(status: 200, body: points_body, headers: { "Content-Type" => "application/json" })
      end

      it "follows the redirect and returns forecast data" do
        expect(result[:current_temp]).to eq(72)
      end
    end

    context "when the points API does not return a forecast URL" do
      let(:points_body) { { "properties" => {} }.to_json }

      it "raises WeatherService::Error" do
        expect { result }.to raise_error(WeatherService::Error, /forecast URL/)
      end
    end

    context "when the points API returns an HTTP error" do
      before do
        stub_request(:get, /weather\.gov\/points/)
          .to_return(status: 503, body: "Service Unavailable")
      end

      it "raises WeatherService::Error" do
        expect { result }.to raise_error(WeatherService::Error, /HTTP 503/)
      end
    end

    context "when the points API returns malformed JSON" do
      let(:points_body) { "not-json" }

      it "raises WeatherService::Error" do
        expect { result }.to raise_error(WeatherService::Error, /invalid JSON/)
      end
    end

    context "when the forecast API times out" do
      before do
        stub_request(:get, /weather\.gov\/gridpoints/).to_timeout
      end

      it "raises WeatherService::Error" do
        expect { result }.to raise_error(WeatherService::Error, /Could not connect/)
      end
    end
  end
end
