require_relative 'base_record'

class SolaredgeRecord < BaseRecord
  def self.csv_options
    { headers: true, col_sep: ',' }
  end

  def self.probe?(first_line)
    first_line.include?('Time,Energie (Wh),ZählerBezugs-Zähler E (Wh),ZählerEinspeise-Zähler E (Wh)')
  end

  def to_a
    data.group_by { |d| d[:measurement] }.map do |measurement, items|
      # Split the day into 5 minute intervals, starting at 00:00:00.
      # This will create 24 * 60 / 5 = 288 records for each day.
      0.step((24 * 60) - 1, 5).map do |minute|
        {
          time: time + (minute * 60),
          name: measurement,

          # Calculate average power (Wh / 24 = W)
          fields: items.to_h { |item| [item[:field], item[:value].fdiv(24)] },
        }
      end
    end.flatten
  end

  def data
    %i[
      inverter_power
      house_power
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
    parse_time(row, 'Time')
  end

  private

  def inverter_power
    @inverter_power ||= parse_kw(row, 'Energie (Wh)')
  end

  def grid_import_power
    @grid_import_power ||= parse_kw(row, 'ZählerBezugs-Zähler E (Wh)')
  end

  def grid_export_power
    @grid_export_power ||= parse_kw(row, 'ZählerEinspeise-Zähler E (Wh)')
  end

  # There is no data for house_power, it has to be calculated
  def house_power
    inverter_power - grid_export_power + grid_import_power
  end

  # KiloWatt
  def parse_kw(row, *)
    cell(row, *).to_f.round
  end
end
