module IptablesWeb
  module Mixin
    module Sudo
      def sudo(command)
        if is_root? || command.include?('sudo')
          command
        else
          "sudo #{command}"
        end
      end

      def is_root?
        Process.uid == 0
      end
    end
  end
end
