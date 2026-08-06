require 'influxdb-client'
require_relative 'line_protocol'

class FluxWriter
  # Points per request. Each write opens its own connection, so a year of
  # SENEC data used to be 420 of them; at this size it is 42, and the body
  # stays under a megabyte.
  BATCH_SIZE = 5_000

  def initialize(config:)
    @config = config
    @line_protocol = LineProtocol.new
  end

  attr_reader :config

  def self.push(config:, records:)
    new(config:).push(records)
  end

  def push(records)
    return unless records

    records.each_slice(BATCH_SIZE) { |chunk| write_chunk(chunk) }
  end

  private

  def write_chunk(chunk)
    data = chunk.filter_map { |record| @line_protocol.call(record) }.join("\n")
    return if data.empty?

    delays = [1, 2, 4]

    begin
      write_api.write(data:, bucket: config.influx_bucket, org: config.influx_org)
    rescue InfluxDB2::InfluxError => e
      raise unless transient?(e) && (delay = delays.shift)

      sleep(delay)
      retry
    end
  end

  # Wrapped network errors (Net::ReadTimeout, ECONNRESET, ...) reach us as
  # InfluxError with a blank `code`; treat those plus 408/429 and any 5xx as
  # transient. Permanent 4xx errors are re-raised immediately.
  def transient?(error)
    return true if error.code.to_s.empty?

    code = error.code.to_i
    code == 408 || code == 429 || (500..599).cover?(code)
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
