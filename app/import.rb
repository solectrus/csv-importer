require 'csv'
require_relative 'flux_writer'
require_relative 'csv_probe'
require_relative 'senec_record'
require_relative 'sungrow_record'

class Import
  def self.run(config:)
    import = new(config:)

    puts "Importing data from #{config.import_folder} ..."

    count = 0
    Dir
      .glob("#{config.import_folder}/**/*.csv")
      .each do |file_path|
        import.process(file_path)
        count += 1

        import.pause
      end

    puts "Imported #{count} files\n\n"

    count
  end

  def initialize(config:)
    @config = config
  end

  attr_reader :config

  def process(file_path)
    print "Importing #{file_path}... "

    record_class = CsvProbe.new(file_path).record_class
    count = 0
    records =
      CSV
        .parse(file_content(file_path), **record_class.csv_options)
        .map do |row|
          count += 1

          record_class.new(row, measurement: config.influx_measurement).to_h
        end

    return unless count.positive?

    FluxWriter.push(config:, records:)
    puts "#{count} points imported"
  end

  def pause
    return unless config.import_pause.positive?

    puts "Pausing for #{config.import_pause} seconds..."
    sleep(config.import_pause)
  end

  def file_content(file_path)
    # Read file content, remove UTF-8 BOM
    content = File.read(file_path, encoding: 'bom|utf-8')

    # Remove Windows line endings (CR+CR+LF -> LF)
    content.gsub("\r\r\n", "\n")
  end
end
