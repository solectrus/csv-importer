# Renders records as InfluxDB line protocol.
#
# `InfluxDB2::Point` does this too, but escapes the measurement and every field
# name again for every point: seven `gsub` over the same handful of strings,
# 1.5 million times for a year of data. A config fixes both, so here they are
# escaped when first seen and looked up afterwards.
#
# The fields go out in the order they arrive. The adapter hands them over
# sorted, which is the order Point used to put them in.
class LineProtocol
  # Applied in one pass, which is what the sequence of `gsub` in Point comes
  # down to: the backslash goes first, and nothing revisits what it inserted.
  KEY_ESCAPES = {
    '\\' => '\\\\',
    ',' => '\\,',
    ' ' => '\\ ',
    '=' => '\\=',
    "\n" => '\n',
    "\r" => '\r',
    "\t" => '\t',
  }.freeze
  KEY_PATTERN = /[\\, =\n\r\t]/

  MEASUREMENT_ESCAPES = KEY_ESCAPES.except('=').freeze
  MEASUREMENT_PATTERN = /[\\, \n\r\t]/

  def initialize
    @measurements = {}
    @keys = {}
  end

  # One record as one line, or nil when it carries no field worth sending.
  def call(record)
    fields = fields(record[:fields])
    return if fields.empty?

    line = "#{measurement(record[:name])} #{fields.join(',')}"
    time = record[:time]
    line << " #{time}" if time

    line
  end

  private

  def fields(fields)
    fields.filter_map do |key, value|
      key = key(key)
      value = value(value)
      "#{key}=#{value}" unless key.empty? || value.nil?
    end
  end

  def measurement(name)
    @measurements[name] ||= begin
      escaped = name.to_s.gsub(MEASUREMENT_PATTERN, MEASUREMENT_ESCAPES)

      # What Point does, for a measurement whose last character is a backslash.
      escaped.end_with?('\\') ? "#{escaped} " : escaped
    end
  end

  def key(key)
    @keys[key] ||= key.to_s.gsub(KEY_PATTERN, KEY_ESCAPES)
  end

  def value(value)
    case value
    when Integer then "#{value}i"
    when Float then value.to_s
    when nil then nil
    else raise(TypeError, "Cannot write #{value.class} as a field value")
    end
  end
end
