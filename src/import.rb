require_relative 'flux_writer'

class Import
  def self.run(config:)
    import = new(config:)

    puts "Importing data from #{config.import_folder} ..."

    count = 0
    Dir
      .glob("#{config.import_folder}/*.csv")
      .each do |filename|
        import.process(filename)
        count += 1
      end

    puts "Imported #{count} files\n\n"
  end

  def initialize(config:)
    @config = config
  end

  attr_reader :config

  def process(filename)
    print "Importing #{filename}... "

    count = 0
    records =
      CSV
        .parse(File.read(filename), headers: true, col_sep: ';')
        .map do |row|
          count += 1

          record(row)
        end

    return unless count.positive?

    FluxWriter.push(config:, records:)
    puts "#{count} points imported"
    return unless config.import_pause.positive?

    puts "Pausing for #{config.import_pause} seconds..."
    sleep(config.import_pause)
  end

  private

  # KiloWatt
  def parse_kw(row, *columns)
    (cell(row, *columns).sub(',', '.').to_f * 1_000).round
  end

  # Ampere
  def parse_a(row, *columns)
    cell(row, *columns).sub(',', '.').to_f
  end

  # Volt
  def parse_v(row, *columns)
    cell(row, *columns).sub(',', '.').to_f
  end

  def cell(row, *columns)
    # Find column with values (can have different names)
    column = columns.find { |col| row[col] }

    row[column]
  end

  def parse_time(row, string)
    Time.parse("#{row[string]} CET").to_i
  end

  def record(row)
    {
      name: 'SENEC',
      time: parse_time(row, 'Uhrzeit'),
      fields: {
        inverter_power: parse_kw(row, 'Stromerzeugung [kW]'),
        house_power: parse_kw(row, 'Stromverbrauch [kW]'),
        bat_power_plus:
          parse_kw(row, 'Akkubeladung [kW]', 'Akku-Beladung [kW]'),
        bat_power_minus:
          parse_kw(row, 'Akkuentnahme [kW]', 'Akku-Entnahme [kW]'),
        bat_fuel_charge: nil,
        bat_charge_current: parse_a(row, 'Akku Stromstärke [A]'),
        bat_voltage: parse_v(row, 'Akku Spannung [V]'),
        grid_power_plus: parse_kw(row, 'Netzbezug [kW]'),
        grid_power_minus: parse_kw(row, 'Netzeinspeisung [kW]'),
      },
    }
  end
end
