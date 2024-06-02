require_relative 'base_record'

class SolaredgeRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ',' }
  end

  def to_a
    # Split the day into 5 minute intervals, starting at 00:00:00.
    # This will create 24 * 60 / 5 = 288 records for each day.
    0.step((24 * 60) - 1, 5).map do |minute|
      {
        name: measurement,
        time: time + (minute * 60),

        # Calculate average power (Wh / 24 = W)
        fields: fields.transform_values { |value| value.fdiv(24) },
      }
    end
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
      # There is no data for house_power, it has to be calculated
      house_power: calculated_house_power,
    }
  end

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
    inverter_power - grid_power_minus + grid_power_plus
  end

  # KiloWatt
  def parse_kw(row, *)
    cell(row, *).to_f.round
  end
end
