require 'dotenv/load'
require 'influxdb-client'
require 'csv'
require 'time'

# KiloWatt
def parse_kw(row, string)
  raise ArgumentError unless string

  (row[string].sub(',', '.').to_f * 1_000).round
end

# Ampere
def parse_a(row, string)
  raise ArgumentError unless string

  row[string].sub(',', '.').to_f
end

# Volt
def parse_v(row, string)
  raise ArgumentError unless string

  row[string].sub(',', '.').to_f
end

def parse_time(row, string)
  Time.parse("#{row[string]} CET").to_i
end

def influx_host
  ENV.fetch('INFLUX_HOST')
end

def influx_schema
  ENV.fetch('INFLUX_SCHEMA', 'http')
end

def influx_port
  ENV.fetch('INFLUX_PORT', '8086')
end

def influx_url
  "#{influx_schema}://#{influx_host}:#{influx_port}"
end

def influx_org
  ENV.fetch('INFLUX_ORG')
end

def influx_bucket
  ENV.fetch('INFLUX_BUCKET')
end

def influx_token
  ENV.fetch('INFLUX_TOKEN')
end

def import_file(filename)
  # Setup InfluxDB
  client = InfluxDB2::Client.new(
    influx_url,
    influx_token,
    use_ssl: influx_schema == 'https',
    precision: InfluxDB2::WritePrecision::SECOND
  )
  write_api = client.create_write_api

  count = 0
  points = CSV.parse(File.read(filename), headers: true, col_sep: ';').map do |row|
    count += 1

    InfluxDB2::Point.new(name: 'SENEC', time: parse_time(row, 'Uhrzeit'))
                    .add_field('inverter_power',     parse_kw(row, 'Stromerzeugung [kW]'))
                    .add_field('house_power',        parse_kw(row, 'Stromverbrauch [kW]'))
                    .add_field('bat_power_plus',     parse_kw(row, 'Akku-Beladung [kW]'))
                    .add_field('bat_power_minus',    parse_kw(row, 'Akku-Entnahme [kW]'))
                    .add_field('bat_fuel_charge',    nil)
                    .add_field('bat_charge_current', parse_a(row, 'Akku Stromstärke [A]'))
                    .add_field('bat_voltage',        parse_v(row, 'Akku Spannung [V]'))
                    .add_field('grid_power_plus',    parse_kw(row, 'Netzbezug [kW]'))
                    .add_field('grid_power_minus',   parse_kw(row, 'Netzeinspeisung [kW]'))
  end

  return unless count.positive?

  write_api.write(data: points, bucket: influx_bucket, org: influx_org)
  puts "#{filename}: #{count} points imported."
end

puts "Starting import...\n\n"

# TODO: Read files in a given folder
import_file('/Users/ledermann/SENEC/week-48-2020.csv')
import_file('/Users/ledermann/SENEC/week-49-2020.csv')
import_file('/Users/ledermann/SENEC/week-50-2020.csv')
import_file('/Users/ledermann/SENEC/week-51-2020.csv')
import_file('/Users/ledermann/SENEC/week-52-2020.csv')
import_file('/Users/ledermann/SENEC/week-53-2020.csv')
