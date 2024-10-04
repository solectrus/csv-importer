require 'spec_helper'

describe EnergyRecord do
  subject(:record) { described_class.new(row, measurement: 'Energy') }

  let(:row) { CSV::Row.new headers, fields }

  let(:headers) { ['Time', 'PV power', 'Load power', 'Battery power', 'Grid power', 'Battery SOC'] }

  describe '#to_h' do
    subject(:hash) { record.to_h }

    let(:fields) { ['2023-06-21 10:50:00', '3000', '400', '-500', '100', '67'] }

    let(:expected_time) { Time.parse('2023-06-21 10:50:00').to_i }

    let(:expected_fields) do
      {
        inverter_power: 3000,
        house_power: 400,
        battery_charging_power: 0,
        battery_discharging_power: 500,
        battery_soc: 67,
        grid_import_power: 100,
        grid_export_power: 0,
      }
    end

    it 'converts the CSV row to a hash with the correct structure and values' do
      expect(hash).to eq(
        { name: 'Energy', time: expected_time, fields: expected_fields },
      )
    end
  end
end
