require_relative 'base_record'

class EnergyRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ',' }
  end

  def self.probe?(first_line)
    first_line.include?('Time,PV power')
  end

  private

  def time
    parse_time(row, 'Time')
  end

  def fields
    {
      inverter_power:,
      house_power:,
      battery_charging_power:,
      battery_discharging_power:,
      battery_soc:,
      grid_import_power:,
      grid_export_power:,
    }
  end

  def inverter_power
    @inverter_power ||= parse_value(row, 'PV power')
  end

  def house_power
    @house_power ||= parse_value(row, 'Load power')
  end

  def battery_soc
    @battery_soc ||= parse_value(row, 'Battery SOC')
  end

  def battery_discharging_power
    @battery_discharging_power ||= bat_power.negative? ? -bat_power : 0
  end

  def battery_charging_power
    @battery_charging_power ||= bat_power.positive? ? bat_power : 0
  end

  def bat_power
    @bat_power ||= parse_value(row, 'Battery power')
  end

  def grid_import_power
    @grid_import_power ||= grid_power.positive? ? grid_power : 0
  end

  def grid_export_power
    @grid_export_power ||= grid_power.negative? ? -grid_power : 0
  end

  def grid_power
    @grid_power ||= parse_value(row, 'Grid power')
  end

  # KiloWatt
  def parse_value(row, *)
    cell(row, *).to_f.round
  end
end
