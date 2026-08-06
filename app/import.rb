require 'csv'
require_relative 'app_logger'
require_relative 'flux_writer'
require_relative 'csv_probe'

class Import
  def self.run(config:)
    import = new(config:)

    AppLogger.instance.info "Importing data from #{config.import_folder} ..."

    count = 0
    Dir
      .glob("#{config.import_folder}/**/*.csv")
      .each do |file_path|
        import.process(file_path)
        count += 1

        import.pause
      end

    AppLogger.instance.info "Imported #{count} files"

    count
  end

  def initialize(config:)
    @config = config
  end

  attr_reader :config

  def process(file_path)
    adapter_class = CsvProbe.new(file_path).adapter_class

    rows = CSV.parse(file_content(file_path), **adapter_class.csv_options)
    headers = rows.shift
    return if rows.empty?

    adapter = adapter_class.new(headers, config:)
    records = rows.flat_map { |row| adapter.points(row) }

    FluxWriter.push(config:, records:)
    AppLogger.instance.info "Imported #{file_path} " \
                              "(#{adapter_class}, #{rows.size} rows)"
  end

  def pause
    return unless config.import_pause.positive?

    AppLogger.instance.info "Pausing for #{config.import_pause} seconds..."
    sleep(config.import_pause)
  end

  def file_content(file_path)
    # Read file content, remove UTF-8 BOM
    content = File.read(file_path, encoding: 'bom|utf-8')

    # Remove Windows line endings (CR+CR+LF -> LF)
    content.gsub("\r\r\n", "\n")
  end
end
