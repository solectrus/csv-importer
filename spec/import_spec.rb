require 'tmpdir'
require 'fileutils'

describe Import do
  let(:config) { Config.from_env(import_pause: 0.01) }

  # A run has one config, and the config fixes the measurement of every sensor.
  # One run over all exports therefore writes every line into the same
  # measurement, whatever file the line came from - and a recorded body does not
  # say which export it holds. One run per vendor names the measurement after
  # the vendor, so the cassettes stay readable and a misread file shows up.
  describe '.run' do
    subject(:run) { described_class.run(config:) }

    let(:config) do
      Config.from_env(
        import_pause: 0.01,
        import_folder: "spec/data/#{folder}",
        **sensors_in(measurement),
      )
    end

    # The measurement of a sensor, and the field it goes under.
    def sensors_in(measurement)
      {
        influx_sensor_inverter_power: "#{measurement}:inverter_power",
        influx_sensor_house_power: "#{measurement}:house_power",
        influx_sensor_grid_import_power: "#{measurement}:grid_power_plus",
        influx_sensor_grid_export_power: "#{measurement}:grid_power_minus",
        influx_sensor_battery_charging_power: "#{measurement}:bat_power_plus",
        influx_sensor_battery_discharging_power:
          "#{measurement}:bat_power_minus",
        influx_sensor_battery_soc: "#{measurement}:bat_fuel_charge",
      }
    end

    context 'with the SENEC exports', vcr: { cassette_name: 'import_senec' } do
      let(:folder) { 'senec' }
      let(:measurement) { 'SENEC' }

      it { is_expected.to eq(5) }
    end

    context 'with the SolarEdge export',
            vcr: { cassette_name: 'import_solaredge' } do
      let(:folder) { 'solaredge' }
      let(:measurement) { 'SolarEdge' }

      it { is_expected.to eq(1) }
    end

    context 'with the Sungrow exports',
            vcr: { cassette_name: 'import_sungrow' } do
      let(:folder) { 'sungrow' }
      let(:measurement) { 'Sungrow' }

      it { is_expected.to eq(2) }
    end
  end

  describe '#process' do
    subject(:process) { import.process(file_path) }

    let(:import) { described_class.new(config:) }
    let(:writer) { instance_double(FluxWriter, push: nil) }

    before { allow(FluxWriter).to receive(:new).and_return(writer) }

    context 'with a file that holds rows' do
      let(:file_path) { 'spec/data/senec/week-11-2022.csv' }

      it 'sends its points' do
        process
        expect(writer).to have_received(:push).once
      end
    end

    context 'with a file that holds nothing but its header row' do
      let(:file_path) { "#{tmp_dir}/header-only.csv" }
      let(:tmp_dir) { Dir.mktmpdir }

      before do
        header = File.open('spec/data/senec/week-11-2022.csv', &:readline)
        File.write(file_path, header)
      end

      after { FileUtils.remove_entry(tmp_dir) }

      it 'sends nothing' do
        process
        expect(writer).not_to have_received(:push)
      end
    end
  end

  describe '#pause' do
    subject(:pause) { import.pause }

    let(:import) { described_class.new(config:) }

    context 'with a pause configured' do
      let(:config) { Config.from_env(import_pause: 0.01) }

      it 'waits' do
        allow(import).to receive(:sleep)

        pause

        expect(import).to have_received(:sleep).with(0.01)
      end
    end

    context 'without a pause configured' do
      let(:config) { Config.from_env(import_pause: 0) }

      it 'does not wait' do
        allow(import).to receive(:sleep)

        pause

        expect(import).not_to have_received(:sleep)
      end
    end
  end
end
