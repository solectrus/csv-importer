require_relative 'base_record'

class SungrowRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ',' }
  end

  def self.probe?(first_line)
    first_line.include?('Zeit,PV-Ertrag(W)')
  end

  def data
    %i[
      inverter_power
      house_power
      battery_charging_power
      battery_discharging_power
      grid_import_power
      grid_export_power
    ].map do |sensor_name|
      {
        measurement: config.measurement(sensor_name),
        field: config.field(sensor_name),
        value: __send__(sensor_name),
      }
    end
  end

  def time
    parse_time(row, 'Zeit')
  end

  private

  def inverter_power
    @inverter_power ||= parse_kw(row, 'PV-Ertrag(W)')
  end

  def house_power
    @house_power ||= parse_kw(row, 'Gesamtverbrauch(W)')
  end

  def battery_charging_power
    @battery_charging_power ||= bat_power.negative? ? -bat_power : 0
  end

  def battery_discharging_power
    @battery_discharging_power ||= bat_power.positive? ? bat_power : 0
  end

  def bat_power
    @bat_power ||= parse_kw(row, 'Batterie(W)')
  end

  def grid_import_power
    @grid_import_power ||= grid_power.positive? ? grid_power : 0
  end

  def grid_export_power
    @grid_export_power ||= grid_power.negative? ? -grid_power : 0
  end

  def grid_power
    @grid_power ||= parse_kw(row, 'Netz(W)')
  end

  # KiloWatt
  def parse_kw(row, *)
    cell(row, *).to_f.round
  end
end
