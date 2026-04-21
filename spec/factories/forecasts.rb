FactoryBot.define do
  factory :forecast do
    zip_code { "10001" }
    current_temp { 72 }
    high_temp { 80 }
    low_temp { 60 }
  end
end
