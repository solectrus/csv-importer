require 'influxdb-client'

class FluxWriter
  def initialize(config:)
    @config = config
  end

  attr_reader :config

  def self.push(config:, records:)
    new(config:).push(records)
  end

  def push(records)
    return unless records

    write_api.write(
      data: records.map { |record| point(record) },
      bucket: config.influx_bucket,
      org: config.influx_org,
    )
  end

  private

  def point(record)
    InfluxDB2::Point.new(
      name: influx_measurement,
      time: record[:time],
      fields: record[:fields],
    )
  end

  def influx_measurement
    'SENEC'
  end

  def influx_client
    @influx_client ||=
      InfluxDB2::Client.new(
        config.influx_url,
        config.influx_token,
        use_ssl: config.influx_schema == 'https',
        precision: InfluxDB2::WritePrecision::SECOND,
        open_timeout: config.influx_open_timeout,
        read_timeout: config.influx_read_timeout,
        write_timeout: config.influx_write_timeout,
      )
  end

  def write_api
    @write_api ||= influx_client.create_write_api
  end
end
