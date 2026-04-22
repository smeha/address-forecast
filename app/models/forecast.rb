# Active Record model for cached forecast data.
# Owns ZIP code validation, the 30-minute cache freshness rule, and the query
# scopes used to display recently updated forecasts.
class Forecast < ApplicationRecord
  # Transient form field — not persisted — carries the raw user input back to the form when geocoding fails.
  attr_accessor :address

  CACHE_TTL = 30.minutes
  ZIP_CODE_FORMAT = /\A\d{5}\z/

  validates :zip_code, presence: true, length: { maximum: 10 }, format: { with: ZIP_CODE_FORMAT, message: "must be a 5-digit US ZIP code" }, uniqueness: true
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: { only_integer: true }

  scope :fresh, -> { where("updated_at > ?", CACHE_TTL.ago) }
  scope :by_recently_updated, -> { order(updated_at: :desc) }

  # Shared by model validations and service layer to avoid duplicating the regex.
  def self.valid_zip_code?(zip_code)
    ZIP_CODE_FORMAT.match?(zip_code.to_s)
  end

  def fresh?
    updated_at > CACHE_TTL.ago
  end
end
