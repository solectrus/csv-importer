require_relative '../app/local_time'

describe LocalTime do
  subject(:local_time) { described_class.new(zone_name) }

  let(:zone_name) { 'Europe/Berlin' }

  describe '#epoch' do
    it 'reads a stamp in winter' do
      expect(local_time.epoch(2022, 3, 14, 0, 13, 13)).to eq(1_647_213_193)
    end

    it 'reads a stamp in summer' do
      expect(local_time.epoch(2023, 9, 22, 16, 0, 0)).to eq(1_695_391_200)
    end

    it 'reads a stamp in another zone' do
      expect(described_class.new('America/New_York').epoch(2023, 9, 22, 16, 0, 0)).to eq(
        1_695_412_800,
      )
    end

    context 'when the clock moves forward that day' do
      it 'reads the hour before the jump' do
        expect(local_time.epoch(2025, 3, 30, 1, 59, 59)).to eq(1_743_296_399)
      end

      it 'reads the hour after the jump' do
        expect(local_time.epoch(2025, 3, 30, 3, 0, 0)).to eq(1_743_296_400)
      end

      # 02:00 does not exist in Europe/Berlin on this day
      it 'reads a stamp the clock skipped as the hour it jumped to' do
        expect(local_time.epoch(2025, 3, 30, 2, 30, 0)).to eq(1_743_298_200)
      end
    end

    context 'when the clock moves back that day' do
      # 02:30 exists twice, once on CEST and once on CET
      it 'reads an hour that exists twice as the first of the two' do
        expect(local_time.epoch(2025, 10, 26, 2, 30, 0)).to eq(1_761_438_600)
      end

      it 'reads a stamp before the jump' do
        expect(local_time.epoch(2025, 10, 26, 1, 0, 0)).to eq(1_761_433_200)
      end

      it 'reads a stamp after the jump' do
        expect(local_time.epoch(2025, 10, 26, 4, 0, 0)).to eq(1_761_447_600)
      end
    end

    # Santiago moves the clock at midnight, so the day has no 00:00:00 at all
    context 'when the day starts on a stamp the clock skipped' do
      let(:zone_name) { 'America/Santiago' }

      it 'reads the stamps of that day' do
        expect(local_time.epoch(2025, 9, 7, 12, 0, 0)).to eq(1_757_257_200)
      end
    end
  end

  describe '.zone' do
    it 'is the zone the import runs in' do
      described_class.zone = 'Europe/Berlin'

      expect(described_class.zone.name).to eq('Europe/Berlin')
    end
  end
end
