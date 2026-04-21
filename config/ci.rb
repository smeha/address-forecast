CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Security: Brakeman", "bin/brakeman --no-pager"
  step "Security: Bundler audit", "bin/bundler-audit"
  step "Lint: RuboCop", "bin/rubocop"
  step "Tests: RSpec", "bundle exec rspec"
end
