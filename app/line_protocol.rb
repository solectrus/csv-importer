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

  # The types of InfluxDB a value can be turned into. A boolean counts as 1
  # or 0. A number never turns into a boolean: a field that InfluxDB holds as
  # boolean and the importer writes as a number is a configuration error.
  NUMERIC_TYPES = %w[integer float].freeze
  BOOLEAN_NUMBERS = { true => 1, false => 0 }.freeze

  def initialize
    @measurements = {}
    @keys = {}
    @types = {}
  end

  # Writes a field of a measurement as the given type from now on, which is
  # the type InfluxDB holds it as already. Nil when there is no way to: the
  # type is not one of NUMERIC_TYPES, or the field has a type already.
  def write_as(measurement, field, type)
    field = field.to_sym
    return if !NUMERIC_TYPES.include?(type) || @types.dig(measurement, field)

    (@types[measurement] ||= {})[field] = type
  end

  # One record as one line, or nil when it carries no field worth sending.
  def call(record)
    fields = fields(record[:fields], @types[record[:name]])
    return if fields.empty?

    line = "#{measurement(record[:name])} #{fields.join(',')}"
    time = record[:time]
    line << " #{time}" if time

    line
  end

  private

  def fields(fields, types)
    fields.filter_map do |key, value|
      value = coerce(value, types[key]) if types
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

  def coerce(value, type)
    return value if type.nil? || value.nil?

    number = BOOLEAN_NUMBERS.fetch(value, value)
    type == 'integer' ? number.round : number.to_f
  end

  def key(key)
    @keys[key] ||= key.to_s.gsub(KEY_PATTERN, KEY_ESCAPES)
  end

  def value(value)
    case value
    when Integer then "#{value}i"
    when Float, true, false then value.to_s
    when nil then nil
    else raise(TypeError, "Cannot write #{value.class} as a field value")
    end
  end
end
