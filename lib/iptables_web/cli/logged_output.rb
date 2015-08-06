module IptablesWeb
  class Cli
    class LoggedOutput < ::HighLine
      def logger
        @logger ||= begin
          logfile = IptablesWeb::log_path
          say("Open log file #{logfile}")
          logger =::Logger.new(logfile)
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
