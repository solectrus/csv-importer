require_relative 'base_record'

class SungrowRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ',' }
  end

  private

  def time
    parse_time(row, 'Zeit')
  end

  def fields
    {
      inverter_power:,
      house_power:,
      bat_power_plus:,
      bat_power_minus:,
      bat_fuel_charge: nil,
      grid_power_plus:,
      grid_power_minus:,
    }
  end

  def inverter_power
    @inverter_power ||= parse_kw(row, 'PV-Ertrag(W)')
  end

  def house_power
    @house_power ||= parse_kw(row, 'Gesamtverbrauch(W)')
  end

  def bat_power_plus
    @bat_power_plus ||= bat_power.negative? ? -bat_power : 0
  end

  def bat_power_minus
    @bat_power_minus ||= bat_power.positive? ? bat_power : 0
  end

  def bat_power
    @bat_power ||= parse_kw(row, 'Batterie(W)')
  end

  def grid_power_plus
    @grid_power_plus ||= grid_power.positive? ? grid_power : 0
  end

  def grid_power_minus
    @grid_power_minus ||= grid_power.negative? ? -grid_power : 0
  end

  def grid_power
    @grid_power ||= parse_kw(row, 'Netz(W)')
  end

  # KiloWatt
  def parse_kw(row, *columns)
    cell(row, *columns).to_f.round
  end
end
