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
            c.option '--print', 'Just print rules'
            c.option '--force', 'Set rules omit checksum check'
            c.option '--dry-run', 'Skip handshake and update'
            c.action do |_, options|
              begin
                IptablesWeb.configuration.load(options.config) if options.config
                logger_log "Use iptables server #{IptablesWeb.api_base_url}"
                IptablesWeb.pid_file do
                  IptablesWeb::Model::Node.handshake(options.dry_run || options.print) do
                    rules = IptablesWeb::Model::AccessRule.all
                    iptables = IptablesWeb::Iptables.new
                    request_etag = rules.response.headers[:etag].first
                    if options.print
                      say iptables.render(rules)
                    else
                      logger_log 'Run client in DRY-RUN mode' if options.dry_run
                      logger_log("Etag value: #{request_etag.inspect}", ::Logger::DEBUG)
                      if IptablesWeb.checksum?(request_etag) && !options.force
                        logger_log '**** Nothing changed ****'
                      else
                        logger_log '*** Iptables updated! ***'
                        if options.dry_run
                          logger_log('New rules:', ::Logger::INFO)
                          logger_log(iptables.render(rules), ::Logger::INFO)
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
                logger_log(e.message, ::Logger::ERROR)
                logger_log(e.backtrace.join("\n"), ::Logger::ERROR)
                raise e
              end
            end
          end
        end
      end
    end
  end
end
