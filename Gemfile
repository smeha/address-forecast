source "https://rubygems.org"

ruby "3.4.8"

gem "rails", "~> 8.1"
gem "pg", "~> 1.6"
gem "puma", ">= 5.0"
gem "sprockets-rails"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "geocoder", "~> 1.8"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development do
  gem "web-console"
end

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rspec", require: false
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rspec-rails", "~> 8.0"
  gem "factory_bot_rails"
  gem "shoulda-matchers"
  gem "webmock"
end
