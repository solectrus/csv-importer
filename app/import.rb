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

  # Rows are parsed, turned into points and sent one batch at a time. Holding
  # a whole file at every stage cost about 45 times its size in memory - and a
  # year of readings in one file is a file somebody has.
  def process(file_path)
    adapter_class = CsvProbe.new(file_path).adapter_class
    adapter = nil
    buffer = []
    rows = 0

    CSV.parse(file_content(file_path), **adapter_class.csv_options) do |row|
      # The first row names the columns, and is what the adapter is built from.
      next adapter = adapter_class.new(row, config:) if adapter.nil?

      rows += 1
      buffer.concat(adapter.points(row))
      next if buffer.size < FluxWriter::BATCH_SIZE

      writer.push(buffer)
      buffer = []
    end
    return if rows.zero?

    writer.push(buffer)
    AppLogger.instance.info "Imported #{file_path} " \
                              "(#{adapter_class}, #{rows} rows)"
  end

  def pause
    return unless config.import_pause.positive?

    AppLogger.instance.info "Pausing for #{config.import_pause} seconds..."
    sleep(config.import_pause)
  end

  def file_content(file_path)
    # Read file content, remove UTF-8 BOM
    content = File.read(file_path, encoding: 'bom|utf-8')

    # Remove Windows line endings (CR+CR+LF -> LF). Replaced in place: the
    # content is ours alone, and a copy of it is one per file thrown away again.
    content.gsub!("\r\r\n", "\n") || content
  end

  private

  # One writer for the whole run: it holds the client, and the names it has
  # escaped once are the same in every file.
  def writer
    @writer ||= FluxWriter.new(config:)
  end
end
