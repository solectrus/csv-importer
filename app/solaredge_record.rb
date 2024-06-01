###--------------------------------------------------------------------------------------------------------------------------------------------###
### Expected column header: Time,Energie (Wh),ZählerBezugs-Zähler E (Wh),ZählerEinspeise-Zähler E (Wh)                                         ###
### Files have to be exported from https://monitoring.solaredge.com/solaredge-web/p/site/<YOURSITE>/#/charts.                                  ###
### On the left, select "Auswerten" an then add all datasources, that shall be exported.                                                       ###
### In this case select: <YOUR_SOLAR-PLANT_NAME>/Energie, Zähler/Bezugs-Zähler/Energie and Zähler/Einspeise-Zähler/Energie                     ###
### In the top right corner of the chartr window, there is the button for csv export.                                                          ###
### Attention: You might need to ask your installer/solarplant-admin to give you the necessary privileges to do exports.                       ###
### During export, select the suitable time window and choose "Täglich" for "Auflösung" (different timespans allow different max. resolutions) ###
###--------------------------------------------------------------------------------------------------------------------------------------------###

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
    calc = inverter_power - grid_power_minus + grid_power_plus
  end

  # KiloWatt
  def parse_kw(row, *)
    cell(row, *).to_f.round
  end
end
