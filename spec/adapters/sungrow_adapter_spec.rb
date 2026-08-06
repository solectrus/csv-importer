describe SungrowAdapter do
  subject(:adapter) { described_class.new(headers, config:) }

  let(:config) do
    Config.from_env(
      influx_sensor_inverter_power: 'Sungrow:inverter_power',
      influx_sensor_house_power: 'Sungrow:house_power',
      influx_sensor_grid_import_power: 'Sungrow:grid_import_power',
      influx_sensor_grid_export_power: 'Sungrow:grid_export_power',
      influx_sensor_battery_charging_power: 'Sungrow:battery_charging_power',
      influx_sensor_battery_discharging_power:
        'Sungrow:battery_discharging_power',
    )
  end

  let(:headers) { %w[Zeit PV-Ertrag(W) Netz(W) Batterie(W) Gesamtverbrauch(W)] }

  describe '#points' do
    subject(:points) { adapter.points(row) }

    let(:row) { ['2023-06-21 10:50:00', '2921', '63', '-2631', '353'] }

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

    it do
      expect(points).to eq(
        [{ name: 'Sungrow', time: expected_time, fields: expected_fields }],
      )
    end

    context 'when the battery discharges and the grid takes the surplus' do
      let(:row) { ['2023-06-21 10:50:00', '2921', '-63', '2631', '353'] }

      it 'splits the pairs the other way' do
        expect(points.first[:fields]).to include(
          battery_charging_power: 0,
          battery_discharging_power: 2631,
          grid_import_power: 0,
          grid_export_power: 63,
        )
      end
    end

    context 'when the timestamp has an unknown shape' do
      let(:row) { ['21.06.2023 10:50:00', '2921', '63', '-2631', '353'] }

      it 'fails' do
        expect { points }.to raise_error(
          ArgumentError,
          /Not a Sungrow timestamp/,
        )
      end
    end

    context 'when a row is too short to reach a column' do
      let(:row) { ['2023-06-21 10:50:00', '2921'] }

      it 'fails' do
        expect { points }.to raise_error(KeyError, /Column Batterie\(W\) is missing/)
      end
    end
  end
end
