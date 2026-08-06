require_relative '../app/flux_writer'

describe FluxWriter do
  let(:writer) { described_class.new(config:) }

  let(:config) do
    Config.new(
      influx_host: 'influx.example.com',
      influx_schema: 'https',
      influx_port: '443',
      influx_token: 'this.is.just.an.example',
      influx_org: 'solectrus',
      influx_bucket: 'my-bucket',
    )
  end

  let(:write_api) { instance_double(InfluxDB2::WriteApi, write: nil) }

  before do
    allow(writer).to receive_messages(write_api:, sleep: nil)
  end

  def make_record(index)
    { time: index, name: 'SENEC', fields: { house_power: index } }
  end

  def influx_error(code:, original: nil)
    InfluxDB2::InfluxError.new(
      original,
      message: 'boom',
      code:,
      reference: '',
      retry_after: '',
    )
  end

  describe '#push' do
    context 'without records' do
      it 'does not call the write API' do
        writer.push(nil)
        expect(write_api).not_to have_received(:write)
      end
    end

    context 'with fewer records than the batch size' do
      let(:records) { Array.new(100) { |i| make_record(i) } }

      it 'writes them in a single batch' do
        writer.push(records)
        expect(write_api).to have_received(:write).once
      end

      it 'writes them as line protocol' do
        payload = nil
        allow(write_api).to receive(:write) { |data:, **| payload = data }

        writer.push(records)

        expect(payload.lines.first).to eq("SENEC house_power=0i 0\n")
      end
    end

    context 'with more records than the batch size' do
      let(:size) { described_class::BATCH_SIZE }
      let(:records) { Array.new((size * 2) + 200) { |i| make_record(i) } }

      it 'splits records into three chunks' do
        writer.push(records)
        expect(write_api).to have_received(:write).exactly(3).times
      end

      it 'preserves chunk sizes' do
        chunk_sizes = []
        allow(write_api).to receive(:write) do |data:, **|
          chunk_sizes << data.lines.size
        end

        writer.push(records)

        expect(chunk_sizes).to eq([size, size, 200])
      end
    end

    context 'with records that carry no field' do
      let(:records) { [{ time: 1, name: 'SENEC', fields: { house_power: nil } }] }

      it 'does not call the write API' do
        writer.push(records)
        expect(write_api).not_to have_received(:write)
      end
    end
  end

  describe 'retry behavior' do
    let(:records) { Array.new(10) { |i| make_record(i) } }

    context 'when the write API raises a wrapped network error' do
      let(:error) { influx_error(code: '', original: Net::ReadTimeout.new) }

      it 'retries until success' do
        call_count = 0
        allow(write_api).to receive(:write) do
          call_count += 1
          raise error if call_count < 3
        end

        writer.push(records)

        expect(call_count).to eq(3)
      end

      it 'backs off using delays 1s, 2s, 4s between retries', :aggregate_failures do
        allow(write_api).to receive(:write).and_raise(error)

        expect { writer.push(records) }.to raise_error(InfluxDB2::InfluxError)
        expect(writer).to have_received(:sleep).with(1).ordered
        expect(writer).to have_received(:sleep).with(2).ordered
        expect(writer).to have_received(:sleep).with(4).ordered
      end

      it 'gives up after the retry budget is exhausted', :aggregate_failures do
        allow(write_api).to receive(:write).and_raise(error)

        expect { writer.push(records) }.to raise_error(InfluxDB2::InfluxError)
        expect(write_api).to have_received(:write).exactly(4).times
      end
    end

    context 'when the response is a 5xx' do
      it 'retries' do
        error = influx_error(code: '503')
        call_count = 0
        allow(write_api).to receive(:write) do
          call_count += 1
          raise error if call_count < 2
        end

        writer.push(records)

        expect(call_count).to eq(2)
      end
    end

    context 'when the response is 408 (Request Timeout)' do
      it 'retries' do
        error = influx_error(code: '408')
        call_count = 0
        allow(write_api).to receive(:write) do
          call_count += 1
          raise error if call_count < 2
        end

        writer.push(records)

        expect(call_count).to eq(2)
      end
    end

    context 'when the response is 429 (Too Many Requests)' do
      it 'retries' do
        error = influx_error(code: '429')
        call_count = 0
        allow(write_api).to receive(:write) do
          call_count += 1
          raise error if call_count < 2
        end

        writer.push(records)

        expect(call_count).to eq(2)
      end
    end

    context 'when the response is a permanent 4xx' do
      let(:error) { influx_error(code: '404') }

      before { allow(write_api).to receive(:write).and_raise(error) }

      it 'raises immediately', :aggregate_failures do
        expect { writer.push(records) }.to raise_error(InfluxDB2::InfluxError)
        expect(write_api).to have_received(:write).once
      end

      it 'does not sleep', :aggregate_failures do
        expect { writer.push(records) }.to raise_error(InfluxDB2::InfluxError)
        expect(writer).not_to have_received(:sleep)
      end
    end
  end
end
