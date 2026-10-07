require 'influxdb-client'
require_relative 'app_logger'
require_relative 'line_protocol'

class FluxWriter
  # Points per request. Each write opens its own connection, so a year of
  # SENEC data used to be 420 of them; at this size it is 42, and the body
  # stays under a megabyte.
  BATCH_SIZE = 5_000

  # What InfluxDB answers for a field that it holds as another type already,
  # in the shard of the point. It names the first such field of a request.
  TYPE_CONFLICT = /
    input\ field\ "(?<field>[^"]+)"\ on\ measurement\ "(?<measurement>[^"]+)"
    \ is\ type\ \w+,\ already\ exists\ as\ type\ (?<type>\w+)
  /x

  def initialize(config:)
    @config = config
    @line_protocol = LineProtocol.new
  end

  attr_reader :config

  def push(records)
    return unless records

    records.each_slice(BATCH_SIZE) { |chunk| write_chunk(chunk) }
  end

  private

  def write_chunk(chunk)
    data = render(chunk)
    return if data.empty?

    delays = [1, 2, 4]

    begin
      write_api.write(data:, bucket: config.influx_bucket, org: config.influx_org)
    rescue InfluxDB2::InfluxError => e
      # InfluxDB dropped the points with the conflict and kept the others. The
      # chunk goes again as a whole, and the points it kept are overwritten.
      if adopt_type(e)
        data = render(chunk)
        retry
      end

      raise unless transient?(e) && (delay = delays.shift)

      sleep(delay)
      retry
    end
  end

  def render(chunk)
    chunk.filter_map { |record| @line_protocol.call(record) }.join("\n")
  end

  # A field in another type than InfluxDB holds it as is written as that type
  # from now on. One conflict costs one more request. A field that conflicts a
  # second time holds two types in different shards, and no type fits both.
  def adopt_type(error)
    match = TYPE_CONFLICT.match(error.message)
    return unless match && @line_protocol.write_as(match[:measurement], match[:field], match[:type])

    AppLogger.instance.info "#{match[:measurement]}:#{match[:field]} exists as " \
                            "#{match[:type]} in InfluxDB, writing it as such"
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
