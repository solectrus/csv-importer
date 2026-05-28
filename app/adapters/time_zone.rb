require 'active_support/all'

def setup_time_zone
  Time.zone = ENV.fetch('TZ', 'Europe/Berlin')
end
