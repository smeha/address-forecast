Rails.application.routes.draw do
  resources :forecasts, only: %i[index show new create destroy]
  get "up" => "rails/health#show", as: :rails_health_check
  root "forecasts#index"
end
