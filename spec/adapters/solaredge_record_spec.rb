describe SolaredgeRecord do
  subject(:record) { described_class.new(row, config:) }

  let(:row) { CSV::Row.new headers, fields }

  let(:headers) { ['Time', 'Energie (Wh)', 'ZählerBezugs-Zähler E (Wh)', 'ZählerEinspeise-Zähler E (Wh)'] }
  let(:fields) { ['30.05.2024', '48958', '6472', '36029'] }
  let(:config) do
    Config.from_env(
      influx_sensor_inverter_power: 'SolarEdge:inverter_power',
      influx_sensor_house_power: 'SolarEdge:house_power',
      influx_sensor_grid_import_power: 'SolarEdge:grid_import_power',
      influx_sensor_grid_export_power: 'SolarEdge:grid_export_power',
    )
  end

  describe '#data' do
    subject(:data) { record.data }

    it do
      expect(data).to eq(
        [
          { field: :inverter_power, measurement: 'SolarEdge', value: 48_958 },
          { field: :house_power, measurement: 'SolarEdge', value: 19_401 },
          { field: :grid_import_power, measurement: 'SolarEdge', value: 6_472 },
          { field: :grid_export_power, measurement: 'SolarEdge', value: 36_029 },
        ],
      )
    end
  end

  describe '#to_a' do
    subject(:array) { record.to_a }

    let(:expected_fields) do
      {
        grid_export_power: 1501,
        grid_import_power: 270,
        house_power: 808,
        inverter_power: 2040,
      }
    end

    it 'create record for each 5 minutes' do
      expect(array.length).to eq(24.hours / 5.minutes)
    end

    it 'converts Wh to W, same for each record' do
      expect(array.pluck(:fields).uniq).to eq([expected_fields])
    end

    it 'creates record with timestamps (first)' do
      expect(array.first[:time]).to  eq('30.05.2024 00:00:00 +0200'.to_time.to_i)
    end

    it 'creates record with timestamps (second)' do
      expect(array.second[:time]).to eq('30.05.2024 00:05:00 +0200'.to_time.to_i)
    end

    it 'creates record with timestamps (last)' do
      expect(array.last[:time]).to   eq('30.05.2024 23:55:00 +0200'.to_time.to_i)
    end
  end
end
