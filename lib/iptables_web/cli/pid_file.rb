module IptablesWeb
  class Cli
    class PidFile

      def initialize(pidfile_path)
        @pidfile = pidfile_path
      end

      def create
        raise AnotherLaunched.new("Another process with #{pid} already launched!") if another_exist?
        logger_log("Create pidfile #{self} for pid #{Process.pid}")
        logger_log("Grab pidfile #{self} for pid #{Process.pid} due process #{pid} is down.") if other?
        File.open(@pidfile, 'w') do |file|
          file.write(Process.pid)
        end
        pid
      end

      def delete
        raise AnotherLaunched.new("Delete error. Another process with #{pid} already launched!") if another_exist?
        logger_log("Delete pidfile #{self} for pid #{pid}")
        File.unlink(@pidfile) if exist?
      end

      def pid
        if exist?
          File.read(@pidfile).to_i
        else
          0
        end
      end

      def another_exist?
        process_exist? && other?
      end

      def other?
        pid > 0 && Process.pid != pid
      end

      def process_exist?
        pid > 0 && Process.kill(0, pid)
      rescue Errno::ESRCH
        false
      end

      def exist?
        ::File.exists?(@pidfile)
      end

      def to_s
        @pidfile
      end

      class PidFileException < Exception
      end

      class AlreadyLaunched < PidFileException
      end

      class AnotherLaunched < PidFileException
      end
    end
  end
end
