require 'uri'

Config =
  Struct.new(
    :influx_schema,
    :influx_host,
    :influx_port,
    :influx_token,
    :influx_org,
    :influx_bucket,
    :influx_measurement,
    :influx_open_timeout,
    :influx_read_timeout,
    :influx_write_timeout,
    :import_folder,
    :import_pause,
    keyword_init: true,
  ) do
    def initialize(*options)
      super

      validate_url!(influx_url)
    end

    def influx_url
      "#{influx_schema}://#{influx_host}:#{influx_port}"
    end

    def self.from_env(options = {})
      new(
        {
          influx_host: ENV.fetch('INFLUX_HOST'),
          influx_schema: ENV.fetch('INFLUX_SCHEMA', 'http'),
          influx_port: ENV.fetch('INFLUX_PORT', '8086'),
          influx_token:
            ENV.fetch('INFLUX_TOKEN_WRITE', nil) || ENV.fetch('INFLUX_TOKEN'),
          influx_org: ENV.fetch('INFLUX_ORG'),
          influx_bucket: ENV.fetch('INFLUX_BUCKET'),
          influx_measurement: ENV.fetch('INFLUX_MEASUREMENT'),
          influx_open_timeout: ENV.fetch('INFLUX_OPEN_TIMEOUT', 30).to_i,
          influx_read_timeout: ENV.fetch('INFLUX_READ_TIMEOUT', 30).to_i,
          influx_write_timeout: ENV.fetch('INFLUX_WRITE_TIMEOUT', 30).to_i,
          import_pause: ENV.fetch('IMPORT_PAUSE', 0).to_i,
          import_folder: ENV.fetch('IMPORT_FOLDER', '/data'),
        }.merge(options),
      )
    end

    private

    def validate_interval!(interval)
      return if interval.is_a?(Integer) && interval.positive?

      throw "Interval is invalid: #{interval}"
    end

    def validate_url!(url)
      uri = URI.parse(url)
      return if uri.is_a?(URI::HTTP) && !uri.host.nil?

      throw "URL is invalid: #{url}"
    end
  end
