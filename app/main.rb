#!/usr/bin/env ruby

require 'dotenv/load'
require_relative 'config'
require_relative 'app_logger'
require_relative 'adapters/time_zone'
require_relative 'import'

setup_time_zone

logger = AppLogger.instance

logger.info 'CSV importer for SOLECTRUS, ' \
              "Version #{ENV.fetch('VERSION', '<unknown>')}, " \
              "built at #{ENV.fetch('BUILDTIME', '<unknown>')}"
logger.info 'https://github.com/solectrus/csv-importer'
logger.info 'Copyright (c) 2020-2026 Georg Ledermann and contributors, released under the MIT License'

config = Config.from_env

logger.info "Using Ruby #{RUBY_VERSION} on platform #{RUBY_PLATFORM}"
logger.info "Pushing to InfluxDB at #{config.influx_url}, bucket #{config.influx_bucket}"
logger.info "Using time zone #{Time.zone.name}"

Import.run(config:)
