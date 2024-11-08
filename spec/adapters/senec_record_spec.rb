describe SenecRecord do
  subject(:record) { described_class.new(row, config:) }

  before do
    ENV['TZ'] = time_zone
    setup_time_zone
  end

  let(:time_zone) { 'Europe/Berlin' }

  let(:config) { Config.from_env }
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

  describe 'Time parsing' do
    subject(:time) { record.time }

    let(:fields) { ['22.09.2023 16:00:00', '', '', '', '', '', '', '', ''] }

    context 'when TZ is Berlin' do
      let(:time_zone) { 'Europe/Berlin' }

      it 'parses time in GMT+2 (DST)' do
        expect(time).to eq(1_695_391_200)
      end
    end

    context 'when TZ is New York' do
      let(:time_zone) { 'America/New_York' }

      it 'parses time in GMT-4 (DST)' do
        expect(time).to eq(1_695_412_800)
      end
    end
  end

  describe '#to_a' do
    subject(:to_a) { record.to_a }

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

    let(:expected_fields) do
      {
        inverter_power: 0,
        house_power: 199,
        bat_power_plus: 0,
        bat_power_minus: 0,
        grid_power_plus: 198,
        grid_power_minus: 0,
      }
    end

    it do
      expect(to_a).to eq([
                           time: 1_647_213_193,
                           name: 'SENEC',
                           fields: expected_fields,
                         ])
    end
  end
end
