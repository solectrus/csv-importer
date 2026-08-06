require_relative '../local_time'

# One adapter per CSV file, built from its header row.
#
# Which column a sensor sits in, which measurement it belongs to and which
# field name it goes under are all fixed by the header row and the config.
# They used to be worked out again for every row - and finding a column by
# name is a walk through the headers, up to three of them per sensor. Here it
# happens once, and a row is read by index afterwards.
class BaseAdapter
  def initialize(headers, config:)
    @config = config
    @index = headers.each_with_index.to_h
    @names = {}
  end

  attr_reader :config

  # The points a row holds - one per measurement it writes to.
  def points(row)
    time = time(row)
    values = values(row)

    groups.map do |measurement, fields|
      { time:, name: measurement, fields: fields_of(fields, values) }
    end
  end

  private

  # Written into a hash rather than collected as pairs first: `to_h` with a
  # block builds an array per field, and throws all of them away again.
  def fields_of(fields, values)
    fields.each_with_object({}) do |(field, sensor), result|
      result[field] = values[sensor]
    end
  end

  # measurement => the fields it carries, and the sensor each of them reads.
  #
  # Sorted by field name, which is the order InfluxDB has been receiving them
  # in all along - it used to be sorted again for every point written.
  def groups
    @groups ||=
      sensors
        .group_by { |sensor| config.measurement(sensor) }
        .map do |measurement, names|
          fields = names.map { |name| [config.field(name), name] }
          [measurement, fields.sort_by { |field, _sensor| field.to_s }]
        end
  end

  # The column one of these names sits in. A file without any of them cannot
  # be read, so this fails for the whole file rather than for every row of it.
  def column(*names)
    optional_column(*names) ||
      raise(KeyError, "Column #{names.join(' or ')} not found")
  end

  def optional_column(*names)
    name = names.find { |candidate| @index.key?(candidate) }
    return unless name

    @names[@index[name]] = name
    @index[name]
  end

  # What a row holds in a column. A row too short to reach it is a broken file,
  # and says which column it lost.
  def read(row, column)
    row[column] || raise(KeyError, "Column #{@names.fetch(column)} is missing")
  end
end
