require "rails_helper"

RSpec.describe Forecast, type: :model do
  subject(:forecast) { build(:forecast) }

  it { is_expected.to be_valid }

  describe "validations" do
    it { is_expected.to validate_presence_of(:zip_code) }
    it { is_expected.to validate_length_of(:zip_code).is_at_most(10) }
    it { is_expected.to validate_presence_of(:current_temp) }
    it { is_expected.to validate_presence_of(:high_temp) }
    it { is_expected.to validate_presence_of(:low_temp) }
    it { is_expected.to validate_numericality_of(:current_temp).only_integer }
    it { is_expected.to validate_numericality_of(:high_temp).only_integer }
    it { is_expected.to validate_numericality_of(:low_temp).only_integer }

    it "rejects a duplicate ZIP code" do
      create(:forecast, zip_code: "10001")
      expect(build(:forecast, zip_code: "10001")).not_to be_valid
    end

    it "rejects a non-numeric ZIP code" do
      forecast.zip_code = "ABCDE"
      expect(forecast).not_to be_valid
      expect(forecast.errors[:zip_code]).to include("must be a 5-digit US ZIP code")
    end

    it "rejects a ZIP code shorter than 5 digits" do
      forecast.zip_code = "1234"
      expect(forecast).not_to be_valid
    end

    it "rejects a ZIP code longer than 5 digits" do
      forecast.zip_code = "123456"
      expect(forecast).not_to be_valid
    end
  end

  describe "#fresh?" do
    it "returns true when updated within 30 minutes" do
      forecast = create(:forecast, updated_at: 10.minutes.ago)
      expect(forecast.fresh?).to be true
    end

    it "returns false when updated more than 30 minutes ago" do
      forecast = create(:forecast, updated_at: 31.minutes.ago)
      expect(forecast.fresh?).to be false
    end
  end

  describe ".fresh scope" do
    it "returns only forecasts updated within 30 minutes" do
      fresh = create(:forecast, zip_code: "10001", updated_at: 5.minutes.ago)
      create(:forecast, zip_code: "90210", updated_at: 45.minutes.ago)

      expect(described_class.fresh).to contain_exactly(fresh)
    end
  end
end
