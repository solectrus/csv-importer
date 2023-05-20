require_relative '../app/config'

describe Config do
  let(:valid_options) do
    {
      influx_host: 'influx.example.com',
      influx_schema: 'https',
      influx_port: '443',
      influx_token: 'this.is.just.an.example',
      influx_org: 'solectrus',
      influx_bucket: 'SENEC',
    }.freeze
  end

  describe '#new' do
    context 'with valid options' do
      subject(:config) { described_class.new(valid_options) }

      it { is_expected.to be_truthy }

      it { expect(config.influx_host).to eq('influx.example.com') }
      it { expect(config.influx_schema).to eq('https') }
      it { expect(config.influx_port).to eq('443') }
      it { expect(config.influx_token).to eq('this.is.just.an.example') }
      it { expect(config.influx_org).to eq('solectrus') }
      it { expect(config.influx_bucket).to eq('SENEC') }
    end

    context 'with missing options' do
      subject(:config) { described_class.new({}) }

      it 'fails' do
        expect { config }.to raise_error(URI::InvalidURIError)
      end
    end

    context 'with invalid options' do
      subject(:config) { described_class.new(influx_host: 'this is no host') }

      it 'fails' do
        expect { config }.to raise_error(URI::InvalidURIError)
      end
    end
  end

  describe '.from_env' do
    subject(:config) { described_class.from_env }

    it { is_expected.to be_truthy }

    it { expect(config.influx_port).to eq('8086') }
    it { expect(config.influx_open_timeout).to eq(30) }
    it { expect(config.influx_read_timeout).to eq(30) }
    it { expect(config.influx_write_timeout).to eq(30) }
    it { expect(config.import_pause).to eq(0) }
  end
end
