require_relative 'base_adapter'

class SolaredgeAdapter < BaseAdapter
  def self.csv_options
    { col_sep: ',' }
  end

  def self.probe?(first_line)
    first_line.include?(
      'Time,Energie (Wh),ZählerBezugs-Zähler E (Wh),ZählerEinspeise-Zähler E (Wh)',
    )
  end

  SENSORS = %i[
    inverter_power
    house_power
    grid_import_power
    grid_export_power
  ].freeze

  # The export reports one row per day. It is spread over the day in 5 minute
  # steps, which makes 24 * 60 / 5 = 288 points per row and measurement.
  INTERVAL = 5 * 60
  OFFSETS = (0...(24 * 60 / 5)).map { |step| step * INTERVAL }.freeze

  def initialize(headers, config:)
    super

    @time_column = column('Time')
    @inverter_column = column('Energie (Wh)')
    @grid_import_column = column('ZählerBezugs-Zähler E (Wh)')
    @grid_export_column = column('ZählerEinspeise-Zähler E (Wh)')
  end

  # Every point of a day carries the same fields, so they are built once and
  # shared - frozen, because 288 points hold the very same hash.
  def points(row)
    midnight = time(row)
    values = values(row)

    groups.flat_map do |measurement, fields|
      shared = fields_of(fields, values).freeze

      OFFSETS.map do |offset|
        { time: midnight + offset, name: measurement, fields: shared }
      end
    end
  end

  def time(row)
    Time.zone.parse(row[@time_column]).to_i
  end

  # The energy of a whole day, read as the average power over it (Wh / 24 = W).
  # There is no reading for the house, so it is what the inverter made plus
  # what came from the grid, less what went to it.
  def values(row)
    inverter = watt_hours(row, @inverter_column)
    grid_import = watt_hours(row, @grid_import_column)
    grid_export = watt_hours(row, @grid_export_column)

    {
      inverter_power: average(inverter),
      house_power: average(inverter - grid_export + grid_import),
      grid_import_power: average(grid_import),
      grid_export_power: average(grid_export),
    }
  end

  private

  def sensors
    SENSORS
  end

  def watt_hours(row, index)
    read(row, index).to_f.round
  end

  def average(watt_hours)
    watt_hours.fdiv(24).round
  end
end
