describe SolectrusRecord do
  subject(:record) { described_class.new(row) }

  let(:row) { CSV::Row.new headers, fields }

  let(:headers) do
    [
      'Uhrzeit',
      'Netzbezug [kW]',
      'Netzeinspeisung [kW]',
      'Stromverbrauch [kW]',
      'Akku-Beladung [kW]',
      'Akku-Entnahme [kW]',
      'Stromerzeugung [kW]',
      'Akku Spannung [V]',
      'Akku Stromstärke [A]',
    ]
  end

  describe '#to_h' do
    subject(:hash) { record.to_h }

    context 'without wallbox calculation' do
      let(:fields) do
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
        ]
      end

      let(:expected_time) { 1_647_213_193 }

      let(:expected_fields) do
        {
          inverter_power: 0,
          house_power: 199,
          bat_power_plus: 0,
          bat_power_minus: 0,
          bat_fuel_charge: nil,
          bat_charge_current: 0.0,
          bat_voltage: 0.0,
          grid_power_plus: 198,
          grid_power_minus: 0,
          wallbox_charge_power: 0,
        }
      end

      it do
        expect(hash).to eq(
          { name: 'SENEC', time: expected_time, fields: expected_fields },
        )
      end
    end

    context 'with wallbox calculation' do
      let(:fields) do
        [
          '21.03.2022 13:00:46',
          '0,00146',
          '0,840947',
          '0,227756',
          '0',
          '0',
          '7,311566',
          '0',
          '0',
        ]
      end

      let(:expected_time) { 1_647_864_046 }

      let(:expected_fields) do
        {
          bat_charge_current: 0.0,
          bat_fuel_charge: nil,
          bat_power_minus: 0,
          bat_power_plus: 0,
          bat_voltage: 0.0,
          grid_power_minus: 841,
          grid_power_plus: 1,
          house_power: 228,
          inverter_power: 7312,
          wallbox_charge_power: 6244,
        }
      end

      it do
        expect(hash).to eq(
          { name: 'SENEC', time: expected_time, fields: expected_fields },
        )
      end
    end
  end
end
