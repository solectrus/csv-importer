require 'logger'

module AppLogger
  # Logger is created lazily so that test-time $stdout redirection
  # is in effect when the underlying IO is captured.
  def self.instance
    @instance ||= build_logger
  end

  def self.build_logger
    $stdout.sync = true
    Logger.new($stdout).tap do |logger|
      logger.formatter = ->(_severity, _time, _progname, msg) { "#{msg}\n" }
    end
  end
end
