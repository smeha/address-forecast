require "rails_helper"

RSpec.describe AddressGeocodingService do
  describe ".lookup" do
    subject(:result) { described_class.lookup("350 5th Ave, New York, NY") }

    let(:geocoder_result) do
      instance_double(
        Geocoder::Result::Base,
        latitude: "40.7484",
        longitude: "-73.9967",
        data: { "address" => { "postcode" => "10001" } }
      )
    end

    before do
      allow(Geocoder).to receive(:search).and_return([ geocoder_result ])
    end

    it "returns latitude, longitude, and ZIP code" do
      expect(result).to eq({ lat: 40.7484, lng: -73.9967, zip_code: "10001" })
    end

    context "when the input is a ZIP code" do
      subject(:result) { described_class.lookup("92130") }

      let(:geocoder_result) do
        instance_double(
          Geocoder::Result::Base,
          latitude: "32.9537",
          longitude: "-117.2310",
          data: {}
        )
      end

      it "uses the ZIP code as the cache key and geocodes it for coordinates" do
        expect(result).to eq({ lat: 32.9537, lng: -117.231, zip_code: "92130" })
        expect(Geocoder).to have_received(:search).with("92130, USA")
      end
    end

    context "when the address is not found" do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it "raises AddressGeocodingService::Error" do
        expect { result }.to raise_error(AddressGeocodingService::Error, /could not be found/)
      end
    end

    context "when the geocoder result does not include a valid ZIP code" do
      let(:geocoder_result) do
        instance_double(
          Geocoder::Result::Base,
          latitude: "40.7484",
          longitude: "-73.9967",
          data: { "address" => {} }
        )
      end

      it "raises AddressGeocodingService::Error" do
        expect { result }.to raise_error(AddressGeocodingService::Error, /valid US ZIP code/)
      end
    end

    context "when the geocoder result does not include valid coordinates" do
      let(:geocoder_result) do
        instance_double(
          Geocoder::Result::Base,
          latitude: nil,
          longitude: "-73.9967",
          data: { "address" => { "postcode" => "10001" } }
        )
      end

      it "raises AddressGeocodingService::Error" do
        expect { result }.to raise_error(AddressGeocodingService::Error, /valid latitude/)
      end
    end

    context "when Geocoder raises a provider error" do
      before do
        allow(Geocoder).to receive(:search).and_raise(Geocoder::Error, "timed out")
      end

      it "raises AddressGeocodingService::Error" do
        expect { result }.to raise_error(AddressGeocodingService::Error, /Could not geocode address/)
      end
    end
  end
end
