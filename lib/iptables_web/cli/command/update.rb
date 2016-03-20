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
            c.option '--dry-run', 'Skip handshake'
            c.action do |_, options|
              begin
                IptablesWeb.configuration.load(options.config) if options.config
                logged_say "Use iptables server #{IptablesWeb.api_base_url}"
                IptablesWeb.pid_file do
                  IptablesWeb::Model::Node.handshake(options.dry_run || options.print) do
                    rules = IptablesWeb::Model::AccessRule.all
                    iptables = IptablesWeb::Iptables.new
                    request_etag = rules.response.headers[:etag].first
                    if options.print
                      logged_say 'Run client in print mode'
                      logged_say '**** Nothing changed ****' if IptablesWeb.checksum?(request_etag)
                      logged_say "Previous checksum #{IptablesWeb.checksum}"
                      logged_say "Current checksum #{IptablesWeb.make_checksum(request_etag)}"
                      say iptables.render(rules)
                    else
                      logged_say 'Run client in DRY-RUN mode' if options.dry_run
                      logged_say("Etag value: #{request_etag.inspect}", ::Logger::DEBUG)
                      if IptablesWeb.checksum?(request_etag) && !options.force
                        logged_say 'Skip iptables update. Nothing changed.'
                      else
                        logged_say '*** Iptables updated! ***'
                        if options.dry_run
                          logger_log('New rules:', ::Logger::DEBUG)
                          logger_log(iptables.render(rules), ::Logger::DEBUG)
                        else
                          iptables.update(rules)
                          logger_log(iptables.diff, ::Logger::DEBUG)
                          IptablesWeb.checksum = request_etag
                        end
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
