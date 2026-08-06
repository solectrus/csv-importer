require_relative 'base_adapter'

class SenecAdapter < BaseAdapter
  def self.csv_options
    { col_sep: ';' }
  end

  def self.probe?(first_line)
    first_line.include?('Uhrzeit;Netzbezug [kW]') ||
      first_line.include?('Uhrzeit;Netzbezug [kWh]')
  end

  # The export has renamed its columns over the years, and reports the same
  # numbers under [kW] and [kWh]. The first name a file carries is the one it
  # means.
  POWER_COLUMNS = {
    inverter_power: ['Stromerzeugung [kW]', 'Stromerzeugung [kWh]'],
    house_power: ['Stromverbrauch [kW]', 'Stromverbrauch [kWh]'],
    battery_charging_power: [
      'Akkubeladung [kW]',
      'Akku-Beladung [kW]',
      'Akku-Beladung [kWh]',
    ],
    battery_discharging_power: [
      'Akkuentnahme [kW]',
      'Akku-Entnahme [kW]',
      'Akku-Entnahme [kWh]',
    ],
    grid_import_power: ['Netzbezug [kW]', 'Netzbezug [kWh]'],
    grid_export_power: ['Netzeinspeisung [kW]', 'Netzeinspeisung [kWh]'],
  }.freeze

  # Battery state of charge. Older exports do not have it.
  SOC_COLUMNS = ['Akku Füllstand [%]', 'Akku-Füllstand [%]'].freeze

  # 14.03.2022 00:13:13
  TIMESTAMP = /\A(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})\z/

  def initialize(headers, config:)
    super

    @time_column = column('Uhrzeit')
    @power_columns =
      POWER_COLUMNS
        .reject { |sensor, _names| ignored?(sensor) }
        .transform_values { |names| column(*names) }
    @soc_column = optional_column(*SOC_COLUMNS) unless ignored?(:battery_soc)
  end

  def time(row)
    stamp = row[@time_column]
    match =
      TIMESTAMP.match(stamp) ||
      raise(ArgumentError, "Not a SENEC timestamp: #{stamp.inspect}")

    LocalTime.zone.epoch(
      match[3].to_i,
      match[2].to_i,
      match[1].to_i,
      match[4].to_i,
      match[5].to_i,
      match[6].to_i,
    )
  end

  def values(row)
    values = {}

    @power_columns.each { |sensor, index| values[sensor] = watt(row, index) }
    values[:battery_soc] = percent(row[@soc_column]) if @soc_column

    values
  end

  private

  def sensors
    @soc_column ? [*@power_columns.keys, :battery_soc] : @power_columns.keys
  end

  def ignored?(sensor)
    config.senec_ignore.include?(config.field(sensor))
  end

  # The decimal comma is replaced in place: the string comes out of the CSV
  # for this row alone, and a copy of it is one per value thrown away again.
  # `tr!` rather than `sub!`, which also leaves a MatchData behind.
  def watt(row, index)
    value = read(row, index)

    ((value.tr!(',', '.') || value).to_f * 1_000).round
  end

  def percent(value)
    return if value.nil? || value.empty?

    (value.tr!(',', '.') || value).to_f.round(2)
  end
end
