describe SolaredgeAdapter do
  subject(:adapter) { described_class.new(headers, config:) }

  let(:headers) do
    [
      'Time',
      'Energie (Wh)',
      'ZählerBezugs-Zähler E (Wh)',
      'ZählerEinspeise-Zähler E (Wh)',
    ]
  end
  let(:row) { ['30.05.2024', '48958', '6472', '36029'] }
  let(:config) do
    Config.from_env(
      influx_sensor_inverter_power: 'SolarEdge:inverter_power',
      influx_sensor_house_power: 'SolarEdge:house_power',
      influx_sensor_grid_import_power: 'SolarEdge:grid_import_power',
      influx_sensor_grid_export_power: 'SolarEdge:grid_export_power',
    )
  end

  describe '#values' do
    subject(:values) { adapter.values(row) }

    # Wh of a whole day, read as the average power over it
    it do
      expect(values).to eq(
        inverter_power: 2040,
        house_power: 808,
        grid_import_power: 270,
        grid_export_power: 1501,
      )
    end
  end

  describe '#points' do
    subject(:points) { adapter.points(row) }

    let(:expected_fields) do
      {
        grid_export_power: 1501,
        grid_import_power: 270,
        house_power: 808,
        inverter_power: 2040,
      }
    end

    it 'creates a point for each 5 minutes' do
      expect(points.length).to eq(24 * 60 / 5)
    end

    it 'converts Wh to W, same for each point' do
      expect(points.map { |point| point[:fields] }.uniq).to eq(
        [expected_fields],
      )
    end

    it 'creates points with timestamps (first)' do
      expect(points.first[:time]).to eq(1_717_020_000)
    end

    it 'creates points with timestamps (second)' do
      expect(points[1][:time]).to eq(1_717_020_300)
    end

    it 'creates points with timestamps (last)' do
      expect(points.last[:time]).to eq(1_717_106_100)
    end

    context 'when a row is too short to reach a column' do
      let(:row) { ['30.05.2024', '48958'] }

      it 'fails' do
        expect { points }.to raise_error(
          KeyError,
          /Column ZählerBezugs-Zähler E \(Wh\) is missing/,
        )
      end
    end
  end
end
