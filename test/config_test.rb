require 'test_helper'

class ConfigTest < Minitest::Test
  VALID_OPTIONS = {
    influx_host: 'influx.example.com',
    influx_schema: 'https',
    influx_port: '443',
    influx_token: 'this.is.just.an.example',
    influx_org: 'solectrus',
    influx_bucket: 'SENEC',
  }.freeze

  def test_valid_options
    Config.new(VALID_OPTIONS)
  end

  def test_invalid_options
    assert_raises(Exception) { Config.new({}) }
    assert_raises(Exception) { Config.new(influx_host: 'this is no host') }
  end

  def test_influx_methods
    config = Config.new(VALID_OPTIONS)

    assert_equal 'influx.example.com', config.influx_host
    assert_equal 'https', config.influx_schema
    assert_equal '443', config.influx_port
    assert_equal 'this.is.just.an.example', config.influx_token
    assert_equal 'solectrus', config.influx_org
    assert_equal 'SENEC', config.influx_bucket
  end

  def test_config_from_env_with_defaults
    config = Config.from_env

    assert_equal 30, config.influx_open_timeout
    assert_equal 30, config.influx_read_timeout
    assert_equal 30, config.influx_write_timeout
    assert_equal '8086', config.influx_port
    assert_equal 0, config.import_pause
  end
end
