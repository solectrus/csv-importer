# Load all adapters
Dir[File.join(__dir__, 'adapters', '*.rb')].each { |file| require file }

class CsvProbe
  def initialize(file_path)
    @file_path = file_path
  end

  attr_reader :file_path

  def record_class
    first_line = File.open(file_path, &:readline).chomp

    # Check all existing record classes (descendands of BaseRecord)
    BaseRecord.descendants.each do |record_class|
      return record_class if record_class.probe?(first_line)
    end

    # If no record class was found, throw an error
    throw "Unknown data format in #{file_path}, first line is #{first_line}"
  end
end
