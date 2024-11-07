describe SungrowRecord do
  subject(:record) { described_class.new(row, config:) }

  let(:row) { CSV::Row.new headers, fields }
  let(:config) do
    Config.from_env(
      influx_sensor_inverter_power: 'Sungrow:inverter_power',
      influx_sensor_house_power: 'Sungrow:house_power',
      influx_sensor_grid_import_power: 'Sungrow:grid_import_power',
      influx_sensor_grid_export_power: 'Sungrow:grid_export_power',
      influx_sensor_battery_charging_power: 'Sungrow:battery_charging_power',
      influx_sensor_battery_discharging_power: 'Sungrow:battery_discharging_power',
    )
  end

  let(:headers) { %w[Zeit PV-Ertrag(W) Netz(W) Batterie(W) Gesamtverbrauch(W)] }

  describe '#to_a' do
    subject(:to_a) { record.to_a }

    let(:fields) { ['2023-06-21 10:50:00', '2921', '63', '-2631', '353'] }

    let(:expected_time) { 1_687_337_400 }

    let(:expected_fields) do
      {
        inverter_power: 2921,
        house_power: 353,
        battery_charging_power: 2631,
        battery_discharging_power: 0,
        grid_import_power: 63,
        grid_export_power: 0,
      }
    end

    it {
      expect(to_a).to eq([
                           name: 'Sungrow',
                           time: expected_time,
                           fields: expected_fields,
                         ])
    }
  end
end
