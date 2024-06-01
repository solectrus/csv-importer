describe SolaredgeRecord do
  subject(:record) { described_class.new(row, measurement: 'SolarEdge') }

  let(:row) { CSV::Row.new headers, fields }

  let(:headers) { ['Time', 'Energie (Wh)', 'ZählerBezugs-Zähler E (Wh)', 'ZählerEinspeise-Zähler E (Wh)'] }

  describe '#to_h' do
    subject(:hash) { record.to_h }

    let(:fields) { ['10.10.2021', '21026', '22153', '1726'] }

    let(:expected_time) { 1_633_816_800 }

    let(:expected_fields) do
      { grid_power_minus: 1726, grid_power_plus: 22_153, house_power: 41_453, inverter_power: 21_026 }
    end

    it do
      expect(hash).to eq(
        { name: 'SolarEdge', time: expected_time, fields: expected_fields },
      )
    end
  end
end
