require 'iptables_web/cli/pid_file'
module IptablesWeb
  class Cli
    module Command
      module Update
        def update_command
          command :update do |c|
            c.syntax = 'iptables-web update'
            c.description = 'Display bar with optional prefix and suffix'
            c.option '--config STRING', String, 'Path to config file'
            c.option '--print', 'Show rules without restoring'
            c.option '--force', 'Set rules omit checksum check'
            c.action do |_, options|
              begin
                IptablesWeb.configuration.load(options.config) if options.config
                logged_say "Use iptables server #{IptablesWeb.api_base_url}"
                IptablesWeb.pid_file do
                  IptablesWeb::Model::Node.handshake do
                    rules = IptablesWeb::Model::AccessRule.all
                    iptables = IptablesWeb::Iptables.new
                    last_checksum = rules.response.headers[:etag].first
                    if options.print
                      logged_say 'Nothing changed.' if IptablesWeb.checksum?(last_checksum)
                      say iptables.render(rules)
                    else
                      if IptablesWeb.checksum?(rules.response.headers[:etag].first) && !options.force
                        logged_say 'Skip iptables update. Nothing changed.'
                      else
                        iptables.restore(rules)
                        IptablesWeb.checksum = last_checksum
                      end
                    end
                  end
                end
              rescue Exception => e
                logged_say(e.message)
                logged_say(e.backtrace.join("\n"))
              end
            end
          end
        end
      end
    end
  end
end
