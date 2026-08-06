require_relative 'local_time'

def setup_time_zone
  LocalTime.zone = ENV.fetch('TZ', 'Europe/Berlin')
end
