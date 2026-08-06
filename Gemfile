source 'https://rubygems.org'

# Loads environment variables from `.env`. (https://github.com/bkeepers/dotenv)
gem 'dotenv'

# Ruby library for InfluxDB 2. (https://github.com/influxdata/influxdb-client-ruby)
gem 'influxdb-client'

# Daylight savings aware timezone library (https://tzinfo.github.io)
gem 'tzinfo'

# Timezone Data for TZInfo (https://tzinfo.github.io)
gem 'tzinfo-data'

# CSV Reading and Writing (https://github.com/ruby/csv)
gem 'csv'

# Both used to arrive by way of ActiveSupport, and neither is a default gem
# any more: `logger` is what AppLogger is built on, `base64` is what the
# InfluxDB client requires to read a Flux answer.
# (https://github.com/ruby/logger, https://github.com/ruby/base64)
gem 'base64'
gem 'logger'

group :development, :test do
  # rspec-3.13.0 (http://github.com/rspec)
  gem 'rspec'

  # Rake is a Make-like program implemented in Ruby (https://github.com/ruby/rake)
  gem 'rake'

  # Automatic Ruby code style checking tool. (https://github.com/rubocop/rubocop)
  gem 'rubocop'

  # Code style checking for RSpec files (https://github.com/rubocop/rubocop-rspec)
  gem 'rubocop-rspec'

  # A RuboCop plugin for Rake (https://github.com/rubocop/rubocop-rake)
  gem 'rubocop-rake'

  # Record your test suite's HTTP interactions and replay them during future test runs for fast, deterministic, accurate tests. (https://benoittgt.github.io/vcr)
  gem 'vcr'

  # Library for stubbing HTTP requests in Ruby. (https://github.com/bblimke/webmock)
  gem 'webmock'

  # Code coverage for Ruby (https://github.com/simplecov-ruby/simplecov)
  gem 'simplecov'
end
