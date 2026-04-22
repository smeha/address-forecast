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

    before do
      allow(GeonamesService).to receive(:coordinates_for).and_return({ lat: 40.7484, lng: -73.9967 })
      allow(WeatherService).to receive(:fetch_forecast).and_return(weather_data)
    end

    context "when no cached forecast exists" do
      it "creates a forecast and redirects to it" do
        post forecasts_path, params: { forecast: { zip_code: "10001" } }
        expect(response).to redirect_to(forecast_path(Forecast.last))
        expect(Forecast.count).to eq(1)
      end
    end

    context "when a fresh cached forecast exists (under 30 minutes old)" do
      let!(:existing) { create(:forecast, zip_code: "10001", updated_at: 10.minutes.ago) }

      it "redirects to the existing forecast without updating" do
        post forecasts_path, params: { forecast: { zip_code: "10001" } }
        expect(response).to redirect_to(forecast_path(existing))
        expect(WeatherService).not_to have_received(:fetch_forecast)
      end
    end

    context "when the cached forecast is stale (over 30 minutes old)" do
      let!(:existing) { create(:forecast, zip_code: "10001", updated_at: 45.minutes.ago) }

      it "updates the existing forecast and redirects to it" do
        post forecasts_path, params: { forecast: { zip_code: "10001" } }
        expect(response).to redirect_to(forecast_path(existing))
        expect(Forecast.count).to eq(1)
        expect(existing.reload.current_temp).to eq(72)
      end
    end

    context "when the GeoNames API fails" do
      before do
        allow(GeonamesService).to receive(:coordinates_for).and_raise(GeonamesService::Error, "ZIP not found")
      end

      it "re-renders the new form with an alert" do
        post forecasts_path, params: { forecast: { zip_code: "99999" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("ZIP not found")
      end
    end

    context "when an invalid ZIP code is submitted" do
      it "re-renders the new form without fetching external data" do
        post forecasts_path, params: { forecast: { zip_code: "ABCDE" } }
        expect(response).to have_http_status(:unprocessable_content)
        expect(GeonamesService).not_to have_received(:coordinates_for)
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
