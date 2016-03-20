module IptablesWeb
  class Cli
    class MultiIO
      def initialize(*targets)
        @targets = targets
      end

      def add(target)
        @targets << target
      end

      def write(*args)
        @targets.each { |t| t.write(*args) }
      end

      def close
        @targets.each(&:close)
      end
    end
  end
end

