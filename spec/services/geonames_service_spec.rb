require "rails_helper"

RSpec.describe GeonamesService do
  before do
    ENV["GEONAMES_API_URL"] = "http://api.geonames.org"
    ENV["GEONAMES_USERNAME"] = "test_user"
  end

  after do
    ENV.delete("GEONAMES_API_URL")
    ENV.delete("GEONAMES_USERNAME")
  end

  describe ".coordinates_for" do
    subject(:result) { described_class.coordinates_for("10001") }

    context "when the ZIP code is found" do
      before do
        stub_request(:get, /geonames\.org/)
          .to_return(
            status: 200,
            body: { "postalcodes" => [ { "lat" => "40.74839", "lng" => "-73.99667" } ] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns lat/lng rounded to 4 decimal places" do
        expect(result).to eq({ lat: 40.7484, lng: -73.9967 })
      end
    end

    context "when the ZIP code is not found" do
      before do
        stub_request(:get, /geonames\.org/)
          .to_return(
            status: 200,
            body: { "postalcodes" => [] }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "raises GeonamesService::Error" do
        expect { result }.to raise_error(GeonamesService::Error, /not found/)
      end
    end
  end
end
