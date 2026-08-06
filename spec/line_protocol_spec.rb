require_relative '../app/line_protocol'

describe LineProtocol do
  subject(:line) { described_class.new.call(record) }

  let(:record) do
    { time: 1_647_213_193, name: 'SENEC', fields: { house_power: 199 } }
  end

  it 'writes a measurement, its fields and the time' do
    expect(line).to eq('SENEC house_power=199i 1647213193')
  end

  it 'marks an integer as one' do
    expect(line).to end_with('house_power=199i 1647213193')
  end

  it 'writes a float as it is' do
    record[:fields] = { bat_fuel_charge: 84.85 }

    expect(line).to eq('SENEC bat_fuel_charge=84.85 1647213193')
  end

  it 'keeps the fields in the order they arrive' do
    record[:fields] = { house_power: 1, bat_power_plus: 2 }

    expect(line).to eq('SENEC house_power=1i,bat_power_plus=2i 1647213193')
  end

  it 'leaves out a field without a value' do
    record[:fields] = { house_power: 199, bat_fuel_charge: nil }

    expect(line).to eq('SENEC house_power=199i 1647213193')
  end

  it 'says nothing when no field is left' do
    record[:fields] = { house_power: nil }

    expect(line).to be_nil
  end

  it 'leaves out a field without a name' do
    record[:fields] = { nil => 199, house_power: 1 }

    expect(line).to eq('SENEC house_power=1i 1647213193')
  end

  it 'writes a record without a time' do
    record[:time] = nil

    expect(line).to eq('SENEC house_power=199i')
  end

  it 'refuses a value it cannot type' do
    record[:fields] = { house_power: '199' }

    expect { line }.to raise_error(TypeError, /Cannot write String/)
  end

  describe 'escaping' do
    it 'escapes a measurement' do
      record[:name] = 'My House, really'

      expect(line).to start_with('My\ House\,\ really ')
    end

    it 'escapes a field name' do
      record[:fields] = { 'house power': 199 }

      expect(line).to eq('SENEC house\ power=199i 1647213193')
    end

    it 'escapes a backslash before anything else' do
      record[:name] = 'a\\,b'

      expect(line).to start_with('a\\\\\\,b ')
    end

    # What InfluxDB2::Point does, and the cassettes were recorded with
    it 'separates a measurement ending in a backslash' do
      record[:name] = 'a\\'

      expect(line).to eq('a\\\\  house_power=199i 1647213193')
    end

    it 'escapes a line break' do
      record[:name] = "a\nb"

      expect(line).to start_with('a\nb ')
    end
  end
end
