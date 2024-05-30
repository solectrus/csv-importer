require_relative 'base_record'

class SolaredgeRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ',' }
  end

  private

  def time
    parse_time(row, 'Time')
  end

  def fields
    {
      inverter_power:,
      grid_power_plus:,
      grid_power_minus:,
      # There is no data for the wallbox, but we can estimate it
      house_power: calculated_house_power,
    }
  end

  #Time,Energie (Wh),ZählerBezugs-Zähler E (Wh),ZählerEinspeise-Zähler E (Wh)

  def inverter_power
    @inverter_power ||= parse_kw(row, 'Energie (Wh)')
  end

  def grid_power_plus
    @grid_power_plus ||= parse_kw(row, 'ZählerBezugs-Zähler E (Wh)')
  end

  def grid_power_minus
    @grid_power_minus ||= parse_kw(row, 'ZählerEinspeise-Zähler E (Wh)')
  end

  def calculated_house_power
    calc = inverter_power - grid_power_minus + grid_power_plus
  end

  # KiloWatt
  def parse_kw(row, *)
    cell(row, *).to_f.round
  end
end
