json.extract! forecast, :id, :zip_code, :current_temp, :low_temp, :high_temp, :created_at, :updated_at
json.url forecast_url(forecast, format: :json)
