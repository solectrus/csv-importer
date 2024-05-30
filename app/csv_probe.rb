require_relative 'senec_record'
require_relative 'sungrow_record'
require_relative 'solaredge_record'

class CsvProbe
  def initialize(file_path)
    @file_path = file_path
  end

  attr_reader :file_path

  def record_class
    first_line = File.open(file_path, &:readline)
    puts "probing file. first line is #{first_line}"
    if senec?(first_line)
      puts 'found senec file'
      SenecRecord
    elsif sungrow?(first_line)
      puts 'found sungrow file'
      SungrowRecord
    elsif solaredge?(first_line)
      puts 'found solaredge file'
      SolaredgeRecord
    else
      throw "Unknown data format in #{file_path}, first line is #{first_line}"
    end
  end

  private

  def senec?(first_line)
    first_line.include?('Uhrzeit;Netzbezug [kW]') ||
      first_line.include?('Uhrzeit;Netzbezug [kWh]')
  end

  def sungrow?(first_line)
    first_line.include?('Zeit,PV-Ertrag(W)')
  end

  def solaredge?(first_line)
    first_line.include?('Time,Energie (Wh),ZählerBezugs-Zähler E (Wh),ZählerEinspeise-Zähler E (Wh)')
  end

end
