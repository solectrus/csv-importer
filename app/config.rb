require 'uri'

SENSOR_NAMES = %i[
  inverter_power
  house_power
  grid_import_power
  grid_export_power
  battery_charging_power
  battery_discharging_power
  wallbox_power
].freeze

Config =
  Struct.new(
    :influx_schema,
    :influx_host,
    :influx_port,
    :influx_token,
    :influx_org,
    :influx_bucket,
    :influx_open_timeout,
    :influx_read_timeout,
    :influx_write_timeout,
    :import_folder,
    :import_pause,
    ### Sensors
    :influx_sensor_inverter_power,
    :influx_sensor_house_power,
    :influx_sensor_grid_import_power,
    :influx_sensor_grid_export_power,
    :influx_sensor_battery_charging_power,
    :influx_sensor_battery_discharging_power,
    :influx_sensor_wallbox_power,
    ###
    keyword_init: true,
  ) do
    def initialize(*options)
      super

      validate_url!(influx_url)
    end

    def influx_url
      "#{influx_schema}://#{influx_host}:#{influx_port}"
    end

    def measurement(sensor_name)
      @measurement ||= {}
      @measurement[sensor_name] ||= splitted_sensor_name(sensor_name)&.first
    end

    def field(sensor_name)
      @field ||= {}
      @field[sensor_name] ||= splitted_sensor_name(sensor_name)&.last&.to_sym
    end

    def splitted_sensor_name(sensor_name)
      public_send(sensor_name.downcase)&.split(':')
    end

    SENSOR_NAMES.each do |sensor_name|
      define_method(sensor_name) do
        public_send("influx_sensor_#{sensor_name}")
      end
    end

    def self.from_env(options = {})
      new(
        {
          influx_host: ENV.fetch('INFLUX_HOST'),
          influx_schema: ENV.fetch('INFLUX_SCHEMA', 'http'),
          influx_port: ENV.fetch('INFLUX_PORT', '8086'),
          influx_token:
            ENV.fetch('INFLUX_TOKEN_WRITE', nil) || ENV.fetch('INFLUX_TOKEN'),
          influx_org: ENV.fetch('INFLUX_ORG'),
          influx_bucket: ENV.fetch('INFLUX_BUCKET'),
          influx_open_timeout: ENV.fetch('INFLUX_OPEN_TIMEOUT', 30).to_i,
          influx_read_timeout: ENV.fetch('INFLUX_READ_TIMEOUT', 30).to_i,
          influx_write_timeout: ENV.fetch('INFLUX_WRITE_TIMEOUT', 30).to_i,
          import_pause: ENV.fetch('IMPORT_PAUSE', 0).to_i,
          import_folder: ENV.fetch('IMPORT_FOLDER', '/data'),
        }.merge(sensors_from_env).merge(options),
      )
    end

    def self.sensors_from_env
      {
        influx_sensor_inverter_power: ENV.fetch('INFLUX_SENSOR_INVERTER_POWER', 'SENEC:inverter_power'),
        influx_sensor_house_power: ENV.fetch('INFLUX_SENSOR_HOUSE_POWER', 'SENEC:house_power'),
        influx_sensor_grid_import_power: ENV.fetch('INFLUX_SENSOR_GRID_IMPORT_POWER', 'SENEC:grid_power_plus'),
        influx_sensor_grid_export_power: ENV.fetch('INFLUX_SENSOR_GRID_EXPORT_POWER', 'SENEC:grid_power_minus'),
        influx_sensor_battery_charging_power: ENV.fetch('INFLUX_SENSOR_BATTERY_CHARGING_POWER', 'SENEC:bat_power_plus'),
        influx_sensor_battery_discharging_power: ENV.fetch(
          'INFLUX_SENSOR_BATTERY_DISCHARGING_POWER', 'SENEC:bat_power_minus',
        ),
        influx_sensor_wallbox_power: ENV.fetch('INFLUX_SENSOR_WALLBOX_POWER', 'SENEC:wallbox_charge_power'),
      }
    end

    private

    def validate_url!(url)
      uri = URI.parse(url)
      return if uri.is_a?(URI::HTTP) && !uri.host.nil?

      throw "URL is invalid: #{url}"
    end
  end
