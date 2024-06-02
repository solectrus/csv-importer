require 'active_support/all'

def setup_time_zone
  time_zone = ENV.fetch('TZ', 'Europe/Berlin')
  Time.zone = time_zone
end

setup_time_zone
