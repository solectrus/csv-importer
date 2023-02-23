require 'test_helper'

class SolectrusRecordTest < Minitest::Test
  def test_to_h
    row =
      CSV::Row.new [
                     'Uhrzeit',
                     'Netzbezug [kW]',
                     'Netzeinspeisung [kW]',
                     'Stromverbrauch [kW]',
                     'Akku-Beladung [kW]',
                     'Akku-Entnahme [kW]',
                     'Stromerzeugung [kW]',
                     'Akku Spannung [V]',
                     'Akku Stromstärke [A]',
                   ],
                   [
                     '14.03.2022 00:13:13',
                     '0,197754',
                     '0',
                     '0,199219',
                     '0',
                     '0',
                     '0',
                     '0',
                     '0',
                   ],
                   true

    record = SolectrusRecord.new(row)

    assert_equal(
      {
        name: 'SENEC',
        time: 1_647_213_193,
        fields: {
          inverter_power: 0,
          house_power: 199,
          bat_power_plus: 0,
          bat_power_minus: 0,
          bat_fuel_charge: nil,
          bat_charge_current: 0.0,
          bat_voltage: 0.0,
          grid_power_plus: 198,
          grid_power_minus: 0,
        },
      },
      record.to_h,
    )
  end
end
