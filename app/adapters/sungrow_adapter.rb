require_relative 'base_adapter'

class SungrowAdapter < BaseAdapter
  def self.csv_options
    { col_sep: ',' }
  end

  def self.probe?(first_line)
    first_line.include?('Zeit,PV-Ertrag(W)')
  end

  SENSORS = %i[
    inverter_power
    house_power
    battery_charging_power
    battery_discharging_power
    grid_import_power
    grid_export_power
  ].freeze

  # 2023-06-21 00:00:00
  TIMESTAMP = /\A(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})\z/

  def initialize(headers, config:)
    super

    @time_column = column('Zeit')
    @inverter_column = column('PV-Ertrag(W)')
    @house_column = column('Gesamtverbrauch(W)')
    @battery_column = column('Batterie(W)')
    @grid_column = column('Netz(W)')
  end

  def time(row)
    stamp = row[@time_column]
    match =
      TIMESTAMP.match(stamp) ||
      raise(ArgumentError, "Not a Sungrow timestamp: #{stamp.inspect}")

    LocalTime.zone.epoch(
      match[1].to_i,
      match[2].to_i,
      match[3].to_i,
      match[4].to_i,
      match[5].to_i,
      match[6].to_i,
    )
  end

  # The battery and the grid report one signed number each, which the two
  # sensors of a pair split between them.
  def values(row)
    battery = watt(row, @battery_column)
    grid = watt(row, @grid_column)

    {
      inverter_power: watt(row, @inverter_column),
      house_power: watt(row, @house_column),
      battery_charging_power: battery.negative? ? -battery : 0,
      battery_discharging_power: battery.positive? ? battery : 0,
      grid_import_power: grid.positive? ? grid : 0,
      grid_export_power: grid.negative? ? -grid : 0,
    }
  end

  private

  def sensors
    SENSORS
  end

  def watt(row, index)
    read(row, index).to_f.round
  end
end
