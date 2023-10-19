class Forecast < ApplicationRecord
	validates :zip_code, presence: true, length: {maximum: 10}
	validates_format_of :zip_code,  :with => /\A\d{5}\z/, :message => "should be valid like example: '12345'"
end
