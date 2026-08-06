require 'tmpdir'
require 'fileutils'

describe Import do
  let(:config) { Config.from_env(import_pause: 0.01) }

  describe '#run', vcr: { cassette_name: 'import' } do
    subject(:run) { described_class.run(config:) }

    it { is_expected.to eq(8) }
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
