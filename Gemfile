source "https://rubygems.org"

# Specify your gem's dependencies in rowdy.gemspec.
gemspec

gem "puma"

gem "sqlite3"

gem "debug"
gem "method_source", "~> 1.0"  # explicit so lockfile is complete (pry dependency)
gem "pry-rails", "~> 0.3.11"

gem "propshaft"
gem "importmap-rails"

# Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
gem "rubocop-rails-omakase", require: false

# Start debugger with binding.b [https://github.com/ruby/debug]
# gem "debug", ">= 1.0.0"

gem "csv"
gem "redis"
gem "sidekiq"
gem "light-service"

group :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "caxlsx"
end
