describe SolaredgeRecord do
  subject(:record) { described_class.new(row, measurement: 'SolarEdge') }

  let(:row) { CSV::Row.new headers, fields }

  let(:headers) { ['Time', 'Energie (Wh)', 'ZählerBezugs-Zähler E (Wh)', 'ZählerEinspeise-Zähler E (Wh)'] }
  let(:fields) { ['30.05.2024', '48958', '6472', '36029'] }

  describe '#to_h' do
    subject(:hash) { record.to_h }

    let(:expected_time) { 1_717_020_000 }

    let(:expected_fields) do
      { grid_power_minus: 36_029, grid_power_plus: 6472, house_power: 19_401, inverter_power: 48_958 }
    end

    it do
      expect(hash).to eq(
        { name: 'SolarEdge', time: expected_time, fields: expected_fields },
      )
    end
  end

  describe '#to_a' do
    subject(:array) { record.to_a }

    let(:expected_fields) do
      {
        grid_power_minus: 1501.2083333333333,
        grid_power_plus: 269.6666666666667,
        house_power: 808.375,
        inverter_power: 2039.9166666666667,
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
