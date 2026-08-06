# Load all adapters
Dir[File.join(__dir__, 'adapters', '*.rb')].each { |file| require file }

class CsvProbe
  def initialize(file_path)
    @file_path = file_path
  end

  attr_reader :file_path

  def adapter_class
    first_line = File.open(file_path, &:readline).chomp

    # Check all existing adapters (subclasses of BaseAdapter)
    BaseAdapter.subclasses.each do |adapter_class|
      return adapter_class if adapter_class.probe?(first_line)
    end

    raise "Unknown data format in #{file_path}, first line is #{first_line}"
  end
end
