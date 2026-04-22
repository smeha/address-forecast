require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  describe "GET /forecasts" do
    it "returns http success" do
      get forecasts_path
      expect(response).to have_http_status(:success)
    end

    it "shows all cached forecasts" do
      create(:forecast, zip_code: "10001")
      create(:forecast, zip_code: "90210")
      get forecasts_path
      expect(response.body).to include("10001", "90210")
    end
  end

  describe "GET /forecasts/:id" do
    let(:forecast) { create(:forecast) }

    it "returns http success" do
      get forecast_path(forecast)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /forecasts/new" do
    it "returns http success" do
      get new_forecast_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /forecasts" do
    let(:weather_data) { { current_temp: 72, high_temp: 80, low_temp: 60 } }
    let(:address) { "350 5th Ave, New York, NY" }
    let(:location) { { lat: 40.7484, lng: -73.9967, zip_code: "10001" } }

    before do
      allow(AddressGeocodingService).to receive(:lookup).and_return(location)
      allow(WeatherService).to receive(:fetch_forecast).and_return(weather_data)
    end

    context "when no cached forecast exists" do
      it "creates a forecast and redirects to it" do
        post forecasts_path, params: { forecast: { address: address } }
        expect(response).to redirect_to(forecast_path(Forecast.last))
        expect(Forecast.count).to eq(1)
        expect(Forecast.last.zip_code).to eq("10001")
      end
    end

    context "when the input is a ZIP code" do
      let(:address) { "92130" }
      let(:location) { { lat: 32.9537, lng: -117.231, zip_code: "92130" } }

      it "creates a forecast for that ZIP code" do
        post forecasts_path, params: { forecast: { address: address } }
        expect(response).to redirect_to(forecast_path(Forecast.last))
        expect(Forecast.last.zip_code).to eq("92130")
        expect(WeatherService).to have_received(:fetch_forecast).with(lat: 32.9537, lng: -117.231)
      end
    end

    context "when a fresh forecast exists for the resolved ZIP code" do
      let!(:existing) { create(:forecast, zip_code: "10001", updated_at: 10.minutes.ago) }

      it "redirects to the existing forecast without fetching weather data" do
        post forecasts_path, params: { forecast: { address: address } }
        expect(response).to redirect_to(forecast_path(existing))
        expect(flash[:notice]).to eq("Forecast was pulled from cache.")
        expect(WeatherService).not_to have_received(:fetch_forecast)
      end
    end

    context "when the forecast for the resolved ZIP code is stale" do
      let!(:existing) { create(:forecast, zip_code: "10001", updated_at: 45.minutes.ago) }

      it "updates the existing forecast and redirects to it" do
        post forecasts_path, params: { forecast: { address: address } }
        expect(response).to redirect_to(forecast_path(existing))
        expect(Forecast.count).to eq(1)
        expect(existing.reload.current_temp).to eq(72)
      end
    end

    context "when address geocoding fails" do
      before do
        allow(AddressGeocodingService).to receive(:lookup).and_raise(AddressGeocodingService::Error, "Address could not be found")
      end

      it "re-renders the new form with an alert" do
        post forecasts_path, params: { forecast: { address: "bad address" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Address could not be found")
        expect(WeatherService).not_to have_received(:fetch_forecast)
      end
    end

    context "when a blank address is submitted" do
      it "re-renders the new form without geocoding or fetching weather data" do
        post forecasts_path, params: { forecast: { address: "" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(AddressGeocodingService).not_to have_received(:lookup)
        expect(WeatherService).not_to have_received(:fetch_forecast)
      end
    end
  end

  describe "DELETE /forecasts/:id" do
    let!(:forecast) { create(:forecast) }

    it "destroys the forecast and redirects to the list" do
      delete forecast_path(forecast)
      expect(response).to redirect_to(forecasts_path)
      expect(Forecast.count).to eq(0)
    end
  end
end
