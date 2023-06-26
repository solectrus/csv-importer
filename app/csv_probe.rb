require_relative 'senec_record'
require_relative 'sungrow_record'

class CsvProbe
  def initialize(file_path)
    @file_path = file_path
  end

  attr_reader :file_path

  def record_class
    first_line = File.open(file_path, &:readline)

    if senec?(first_line)
      SenecRecord
    else
      throw "Unknown data format in #{file_path}, first line is #{first_line}"
    end
  end

  private

  def senec?(first_line)
    first_line.include?('Uhrzeit;Netzbezug [kW]') ||
      first_line.include?('Uhrzeit;Netzbezug [kWh]')
  end
end
