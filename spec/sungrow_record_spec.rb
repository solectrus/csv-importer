describe SungrowRecord do
  subject(:record) { described_class.new(row, measurement: 'Sungrow') }

  let(:row) { CSV::Row.new headers, fields }

  let(:headers) { %w[Zeit PV-Ertrag(W) Netz(W) Batterie(W) Gesamtverbrauch(W)] }

  describe '#to_h' do
    subject(:hash) { record.to_h }

    let(:fields) { ['2023-06-21 10:50:00', '2921', '63', '-2631', '353'] }

    let(:expected_time) { 1_687_337_400 }

    let(:expected_fields) do
      {
        inverter_power: 2921,
        house_power: 353,
        bat_power_plus: 2631,
        bat_power_minus: 0,
        bat_fuel_charge: nil,
        grid_power_plus: 63,
        grid_power_minus: 0,
      }
    end

    it do
      expect(hash).to eq(
        { name: 'Sungrow', time: expected_time, fields: expected_fields },
      )
    end
  end
end
