class Forecast < ApplicationRecord
  CACHE_TTL = 30.minutes.ago

  validates :zip_code, presence: true, length: { maximum: 10 }, format: { with: /\A\d{5}\z/, message: "must be a 5-digit US ZIP code" }
  validates :current_temp, :high_temp, :low_temp, presence: true, numericality: { only_integer: true }

  scope :fresh, -> { where("updated_at > ?", CACHE_TTL) }
  scope :by_recently_updated, -> { order(updated_at: :desc) }

  def fresh?
    updated_at > CACHE_TTL
  end
end
