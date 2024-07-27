describe Import do
  let(:config) { Config.from_env(import_pause: 0.01) }

  describe '#run', vcr: { cassette_name: 'import' } do
    subject(:run) { described_class.run(config:) }

    it { is_expected.to eq(9) }
  end
end
