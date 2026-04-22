class Forecast < ApplicationRecord
  CACHE_TTL = 30.minutes
  ZIP_CODE_FORMAT = /\A\d{5}\z/

  validates :zip_code, presence: true, length: { maximum: 10 }, format: { with: ZIP_CODE_FORMAT, message: "must be a 5-digit US ZIP code" }
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: { only_integer: true }

  scope :fresh, -> { where("updated_at > ?", CACHE_TTL.ago) }
  scope :by_recently_updated, -> { order(updated_at: :desc) }

  def self.valid_zip_code?(zip_code)
    ZIP_CODE_FORMAT.match?(zip_code.to_s)
  end

  def fresh?
    updated_at > CACHE_TTL.ago
  end
end
