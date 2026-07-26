require 'uri'

SENSOR_NAMES = %i[
  inverter_power
  house_power
  grid_import_power
  grid_export_power
  battery_charging_power
  battery_discharging_power
  battery_soc
].freeze

Config =
  Data.define(
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
    :influx_sensor_battery_soc,
    ### SENEC only: Optionally ignore some fields
    :senec_ignore,
    ###
  ) do
    def initialize(**args)
      # Pre-super ivars survive the auto-freeze that Data applies after super.
      @measurement = {}
      @field = {}

      defaults = self.class.members.to_h { |m| [m, nil] }
      super(**defaults.merge(args))

      validate_url!(influx_url)
    end

    def influx_url
      "#{influx_schema}://#{influx_host}:#{influx_port}"
    end

    def measurement(sensor_name)
      @measurement[sensor_name] ||= splitted_sensor_name(sensor_name)&.first
    end

    def field(sensor_name)
      @field[sensor_name] ||= splitted_sensor_name(sensor_name)&.last&.to_sym
    end

    def splitted_sensor_name(sensor_name)
      public_send(:"influx_sensor_#{sensor_name}")&.split(':')
    end

    def self.from_env(**)
      new(**from_env_defaults, **)
    end

    def self.from_env_defaults
      {
        influx_host: ENV.fetch('INFLUX_HOST', nil),
        influx_schema: ENV.fetch('INFLUX_SCHEMA', 'http'),
        influx_port: ENV.fetch('INFLUX_PORT', '8086'),
        influx_token:
          ENV.fetch('INFLUX_TOKEN_WRITE', nil) || ENV.fetch('INFLUX_TOKEN', nil),
        influx_org: ENV.fetch('INFLUX_ORG', nil),
        influx_bucket: ENV.fetch('INFLUX_BUCKET', nil),
        influx_open_timeout: ENV.fetch('INFLUX_OPEN_TIMEOUT', 30).to_i,
        influx_read_timeout: ENV.fetch('INFLUX_READ_TIMEOUT', 60).to_i,
        influx_write_timeout: ENV.fetch('INFLUX_WRITE_TIMEOUT', 30).to_i,
        import_pause: ENV.fetch('IMPORT_PAUSE', 0).to_i,
        import_folder: ENV.fetch('IMPORT_FOLDER', '/data'),
        **sensors_from_env,
      }
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
        influx_sensor_battery_soc: ENV.fetch('INFLUX_SENSOR_BATTERY_SOC', 'SENEC:bat_fuel_charge'),
        senec_ignore: ENV.fetch('SENEC_IGNORE', '').split(',').map(&:to_sym),
      }
    end

    private

    def validate_url!(url)
      uri = URI.parse(url)
      return if uri.is_a?(URI::HTTP) && !uri.host.to_s.empty?

      raise ArgumentError, "URL is invalid: #{url}"
    end
  end
