require_relative 'time_zone'

class BaseRecord
  def initialize(row, measurement:)
    @row = row
    @measurement = measurement
  end

  attr_reader :row, :measurement

  def to_h
    { name: measurement, time:, fields: }
  end

  private

  # Time
  def parse_time(row, string)
    Time.zone.parse(row[string]).to_i
  end

  def cell(row, *columns)
    # Find column by name (can have different names due to CSV format changes)
    column = columns.find { |col| row[col] }

    row[column] || throw("Column #{columns.join(' or ')} not found")
  end
end
