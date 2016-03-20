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
          @log_io = MultiIO.new(File.open(logfile, 'a'))
          logger =::Logger.new(@log_io)
          logger.formatter = ::Logger::Formatter.new
          logger
        end
      end

      def log_stdout
        @log_io.add(STDOUT)
      end

      def log_level=(log_level)
        log_level = LOG_LEVEL_MAP[log_level] if LOG_LEVEL_MAP[log_level]
        logger.level = log_level.to_i
      end

      def log_level
        logger.level
      end

      def reset
        @logger = nil
      end

      def logger_log(message, log_level = Logger::INFO)
        logger.log(log_level, message.to_s.strip) if logger
      end

      # def logger_log(message, log_level = Logger::INFO)
      #   logger_log(message, log_level)
      #   say(message)
      # end
    end
  end
end
