describe SenecAdapter do
  subject(:adapter) { described_class.new(headers, config:) }

  before do
    ENV['TZ'] = time_zone
    setup_time_zone
  end

  let(:time_zone) { 'Europe/Berlin' }

  let(:config) { Config.from_env }

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

  describe '#time' do
    subject(:time) { adapter.time(row) }

    let(:row) { ['22.09.2023 16:00:00', '', '', '', '', '', '', '', ''] }

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

    context 'when the timestamp has an unknown shape' do
      let(:row) { ['2023-09-22T16:00:00', '', '', '', '', '', '', '', ''] }

      it 'fails' do
        expect { time }.to raise_error(ArgumentError, /Not a SENEC timestamp/)
      end
    end
  end

  describe '#points' do
    subject(:points) { adapter.points(row) }

    let(:row) do
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
      expect(points).to eq(
        [{ time: 1_647_213_193, name: 'SENEC', fields: expected_fields }],
      )
    end

    context 'when a column is missing from the header row' do
      let(:headers) { ['Uhrzeit', 'Netzbezug [kW]'] }

      it 'fails for the whole file' do
        expect { adapter }.to raise_error(
          KeyError,
          /Column Stromerzeugung \[kW\] or Stromerzeugung \[kWh\] not found/,
        )
      end
    end

    context 'when a row is too short to reach a column' do
      let(:row) { ['14.03.2022 00:13:13', '0,197754'] }

      it 'fails' do
        expect { points }.to raise_error(
          KeyError,
          /Column Stromerzeugung \[kW\] is missing/,
        )
      end
    end

    context 'when a sensor is ignored' do
      let(:config) { Config.from_env(senec_ignore: %i[bat_power_plus]) }

      it 'leaves the field out' do
        expect(points.first[:fields].keys).not_to include(:bat_power_plus)
      end
    end
  end

  describe '#points with the battery fill level column' do
    subject(:points) { adapter.points(row) }

    let(:headers) do
      [
        'Uhrzeit',
        'Netzbezug [kW]',
        'Netzeinspeisung [kW]',
        'Stromverbrauch [kW]',
        'Akkubeladung [kW]',
        'Akkuentnahme [kW]',
        'Stromerzeugung [kW]',
        'Akku Spannung [V]',
        'Akku Stromstärke [A]',
        'Akku Füllstand [%]',
      ]
    end

    let(:fill_level) { '84,84848' }
    let(:row) do
      [
        '26.09.2022 13:13:09',
        '0,005859',
        '0,011719',
        '0,433594',
        '0,908203',
        '0',
        '1,359375',
        '56,040001',
        '15,26',
        fill_level,
      ]
    end

    it 'includes the battery state of charge' do
      expect(points.first[:fields]).to include(bat_fuel_charge: 84.85)
    end

    context 'when the fill level is empty' do
      let(:fill_level) { '' }

      it 'reports no state of charge' do
        expect(points.first[:fields]).to include(bat_fuel_charge: nil)
      end
    end

    context 'when the state of charge is ignored' do
      let(:config) { Config.from_env(senec_ignore: %i[bat_fuel_charge]) }

      it 'leaves the field out' do
        expect(points.first[:fields].keys).not_to include(:bat_fuel_charge)
      end
    end
  end
end
