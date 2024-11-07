require_relative 'time_zone'

class BaseRecord
  def initialize(row, config:)
    @row = row
    @config = config
  end

  attr_reader :row, :config

  def to_a
    data.group_by { |d| d[:measurement] }.map do |measurement, items|
      {
        time:,
        name: measurement,
        fields: items.to_h { |item| [item[:field], item[:value]] },
      }
    end
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
