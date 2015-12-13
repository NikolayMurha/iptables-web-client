module IptablesWeb
  class Cli
    class LoggedOutput < ::HighLine

      LOG_LEVEL_MAP = {
        'debug' => ::Logger::DEBUG,
        'info' => ::Logger::INFO,
        'warn' => ::Logger::WARN,
        'error' => ::Logger::ERROR,
        'fatal' => ::Logger::FATAL,
        'unknown' => ::Logger::UNKNOWN,
      }

      def logger
        @logger ||= begin
          logfile = IptablesWeb::log_path
          log_level = IptablesWeb::log_level
          log_level = LOG_LEVEL_MAP[log_level] if LOG_LEVEL_MAP[log_level]
          log_level = log_level.to_i
          say("Open log file #{logfile}")
          logger =::Logger.new(logfile)
          logger.level = log_level.to_i
          logger.formatter = ::Logger::Formatter.new
          logger
        end
      end

      def reset
        @logger = nil
      end

      def logged_say(message, log_level = Logger::INFO)
        logger.log(log_level, message) if logger
        say(message)
      end
    end
  end
end
