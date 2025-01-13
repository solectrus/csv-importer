#!/usr/bin/env ruby

require 'dotenv/load'
require_relative 'config'
require_relative 'import'

# Flush output immediately
$stdout.sync = true

puts 'CSV importer for SOLECTRUS, ' \
       "Version #{ENV.fetch('VERSION', '<unknown>')}, " \
       "built at #{ENV.fetch('BUILDTIME', '<unknown>')}"
puts 'https://github.com/solectrus/csv-importer'
puts 'Copyright (c) 2020-2025 Georg Ledermann and contributors, released under the MIT License'
puts "\n"

config = Config.from_env

puts "Using Ruby #{RUBY_VERSION} on platform #{RUBY_PLATFORM}"
puts "Pushing to InfluxDB at #{config.influx_url}, bucket #{config.influx_bucket}"
puts "Using time zone #{Time.zone.name}"
puts "\n"

Import.run(config:)
