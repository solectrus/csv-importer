require_relative '../app/config'

describe Config do
  let(:valid_options) do
    {
      influx_host: 'influx.example.com',
      influx_schema: 'https',
      influx_port: '443',
      influx_token: 'this.is.just.an.example',
      influx_org: 'solectrus',
      influx_bucket: 'my-bucket',
    }.freeze
  end

  describe '#new' do
    context 'with valid options' do
      subject(:config) { described_class.new(**valid_options) }

      it { is_expected.to be_truthy }

      it { expect(config.influx_host).to eq('influx.example.com') }
      it { expect(config.influx_schema).to eq('https') }
      it { expect(config.influx_port).to eq('443') }
      it { expect(config.influx_token).to eq('this.is.just.an.example') }
      it { expect(config.influx_org).to eq('solectrus') }
      it { expect(config.influx_bucket).to eq('my-bucket') }
    end

    context 'with missing options' do
      subject(:config) { described_class.new }

      it 'fails' do
        expect { config }.to raise_error(URI::InvalidURIError)
      end
    end

    context 'with missing INFLUX_HOST' do
      subject(:config) { described_class.new(influx_host: nil) }

      it 'fails' do
        expect { config }.to raise_error(URI::InvalidURIError)
      end
    end

    context 'with missing INFLUX_HOST, but schema and port present' do
      subject(:config) do
        described_class.new(**valid_options, influx_host: nil)
      end

      it 'fails' do
        expect { config }.to raise_error(
          ArgumentError,
          'URL is invalid: https://:443',
        )
      end
    end

    context 'with blank INFLUX_HOST' do
      subject(:config) { described_class.new(**valid_options, influx_host: '') }

      it 'fails' do
        expect { config }.to raise_error(
          ArgumentError,
          'URL is invalid: https://:443',
        )
      end
    end

    context 'with invalid INFLUX_SCHEMA' do
      subject(:config) { described_class.new(influx_schema: 'foo') }

      it 'fails' do
        expect { config }.to raise_error(StandardError)
      end
    end
  end

  describe '#measurement and #field' do
    context 'with a sensor configured' do
      subject(:config) do
        described_class.new(
          **valid_options,
          influx_sensor_battery_soc: 'SENEC:bat_fuel_charge',
        )
      end

      it { expect(config.measurement(:battery_soc)).to eq('SENEC') }
      it { expect(config.field(:battery_soc)).to eq(:bat_fuel_charge) }
    end

    # `Config.new` leaves every member it is not given as nil
    context 'without a sensor configured' do
      subject(:config) { described_class.new(**valid_options) }

      it { expect(config.measurement(:battery_soc)).to be_nil }
      it { expect(config.field(:battery_soc)).to be_nil }
    end
  end

  describe '.from_env' do
    subject(:config) { described_class.from_env }

    it { is_expected.to be_truthy }

    it { expect(config.influx_port).to eq('8086') }
    it { expect(config.influx_open_timeout).to eq(30) }
    it { expect(config.influx_read_timeout).to eq(60) }
    it { expect(config.influx_write_timeout).to eq(30) }
    it { expect(config.import_pause).to eq(1) }
  end
end
