require_relative 'base_record'

class SenecRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ';' }
  end

  def self.probe?(first_line)
    first_line.include?('Uhrzeit;Netzbezug [kW]') ||
      first_line.include?('Uhrzeit;Netzbezug [kWh]')
  end

  BASE_SENSORS = %i[
    inverter_power
    house_power
    battery_charging_power
    battery_discharging_power
    grid_import_power
    grid_export_power
  ].freeze

  SENSORS_WITH_SOC = (BASE_SENSORS + %i[battery_soc]).freeze

  SOC_COLUMNS = ['Akku Füllstand [%]', 'Akku-Füllstand [%]'].freeze

  def data
    sensor_names.filter_map do |sensor_name|
      next if config.senec_ignore.include?(config.field(sensor_name))

      {
        measurement: config.measurement(sensor_name),
        field: config.field(sensor_name),
        value: __send__(sensor_name),
      }
    end
  end

  def time
    parse_time(row, 'Uhrzeit')
  end

  private

  def sensor_names
    @sensor_names ||=
      SOC_COLUMNS.intersect?(row.headers) ? SENSORS_WITH_SOC : BASE_SENSORS
  end

  def inverter_power
    @inverter_power ||=
      parse_kw(row, 'Stromerzeugung [kW]', 'Stromerzeugung [kWh]')
  end

  def house_power
    @house_power ||=
      parse_kw(row, 'Stromverbrauch [kW]', 'Stromverbrauch [kWh]')
  end

  def battery_charging_power
    @battery_charging_power ||=
      parse_kw(
        row,
        'Akkubeladung [kW]',
        'Akku-Beladung [kW]',
        'Akku-Beladung [kWh]',
      )
  end

  def battery_discharging_power
    # The CSV file format has changed over time, so two different column names are possible
    @battery_discharging_power ||=
      parse_kw(
        row,
        'Akkuentnahme [kW]',
        'Akku-Entnahme [kW]',
        'Akku-Entnahme [kWh]',
      )
  end

  def grid_import_power
    @grid_import_power ||= parse_kw(row, 'Netzbezug [kW]', 'Netzbezug [kWh]')
  end

  def grid_export_power
    @grid_export_power ||=
      parse_kw(row, 'Netzeinspeisung [kW]', 'Netzeinspeisung [kWh]')
  end

  # Battery state of charge (percentage). Optional — older CSV exports
  # don't include this column.
  def battery_soc
    return @battery_soc if defined?(@battery_soc)

    raw = SOC_COLUMNS.filter_map { |col| row[col] }.first
    @battery_soc = raw.nil? || raw.empty? ? nil : raw.sub(',', '.').to_f.round(2)
  end

  # KiloWatt
  def parse_kw(row, *)
    (cell(row, *).sub(',', '.').to_f * 1_000).round
  end
end
