describe Import do
  let(:config) { Config.from_env }

  describe '#run', vcr: { cassette_name: 'import' } do
    subject(:run) { described_class.run(config:) }

    it { is_expected.to eq(4) }
  end
end
