require 'tzinfo'

# Wall-clock time in a time zone, as epoch seconds.
#
# TZInfo answers this. What is ours is the zone the import runs in, and what to
# answer on the two days a year the clock moves.
class LocalTime
  class << self
    # The zone the import runs in. Set once at startup, as `Time.zone` was.
    attr_reader :zone

    def zone=(name)
      @zone = new(name)
    end
  end

  def initialize(name)
    @name = name
    @timezone = TZInfo::Timezone.get(name)
  end

  attr_reader :name

  # `dst: true` reads an hour that exists twice as the first of the two.
  def epoch(year, month, day, hour, minute, second)
    timestamp =
      @timezone.local_timestamp(year, month, day, hour, minute, second, 0, true)

    timestamp.value
  rescue TZInfo::PeriodNotFound
    # A stamp the clock skipped is read as the hour it jumped to.
    jumped = Time.utc(year, month, day, hour, minute, second) + 3600

    epoch(jumped.year, jumped.month, jumped.day, jumped.hour, jumped.min, jumped.sec)
  end
end
