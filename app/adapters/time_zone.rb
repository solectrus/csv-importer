require 'active_support'
require 'active_support/core_ext/time'

def setup_time_zone
  Time.zone = ENV.fetch('TZ', 'Europe/Berlin')
end
