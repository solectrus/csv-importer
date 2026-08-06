describe CsvProbe do
  let(:checker) { described_class.new(file_path) }

  describe '#adapter_class' do
    context 'when a Senec file is given' do
      Dir
        .glob('spec/data/senec/*.csv')
        .each do |file_path|
          let(:file_path) { file_path }

          it 'returns the SenecAdapter class' do
            expect(checker.adapter_class).to eq(SenecAdapter)
          end
        end
    end

    context 'when a Sungrow file is given' do
      Dir
        .glob('spec/data/sungrow/*.csv')
        .each do |file_path|
          let(:file_path) { file_path }

          it 'returns the SungrowAdapter class' do
            expect(checker.adapter_class).to eq(SungrowAdapter)
          end
        end
    end

    context 'when a SolarEdge file is given' do
      Dir
        .glob('spec/data/solaredge/*.csv')
        .each do |file_path|
          let(:file_path) { file_path }

          it 'returns the SolaredgeAdapter class' do
            expect(checker.adapter_class).to eq(SolaredgeAdapter)
          end
        end
    end

    context 'when something different is given' do
      let(:file_path) { 'README.md' }

      it 'fails' do
        expect { checker.adapter_class }.to raise_error(
          StandardError,
          /Unknown data format in README.md/,
        )
      end
    end
  end
end
