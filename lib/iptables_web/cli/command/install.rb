module IptablesWeb
  class Cli
    module Command
      module Install
        def install_command
          command :crontab do |c|

          end

          command :install do |c|
            c.syntax = 'iptables-web install'
            c.description = 'Displays foo'
            c.option '--force', 'Force config '
            c.action do |args, options|
              # TODO: Should be refactored
              config = IptablesWeb::Configuration.new
              api_url = ask('Api base url: ') { |q| q.default = config['api_base_url'] }
              token = ask('Access token: ') { |q| q.default = config['access_token'] }
              update_period = ask('Update every [min]', Integer) { |q| q.default = 1; q.in = 0..59 }
              config_path = IptablesWeb.config_path
              config_dir = File.dirname(IptablesWeb.config_path)
              unless File.exist?(config_dir)
                say "Create config directory: #{config_dir}"
                Dir.mkdir(File.dirname(config_dir))
              end
              say "Write config to #{config_path}"
              File.write config_path, <<CONFIG
api_base_url: #{api_url}
access_token: #{token}
CONFIG
              if system("LANG=C bash -l -c \"type rvm | cat | head -1 | grep -q '^rvm is a function$'\"")
                wrapper = 'rvm system do iptables-web'
              else
                wrapper = 'iptables-web'
              end

              cron_file = File.join(config_dir, 'cron.sh')
              say "Write file #{cron_file}"
              File.write cron_file, <<CONFIG
#/bin/env ruby
#{wrapper}
CONFIG
              File.chmod(0700, cron_file)
              say "Add cronjob #{cron_file}"
              crontab = IptablesWeb::Crontab.new(false)
              jobs = crontab.jobs
              jobs.reject! { |job| job.include?('.iptables-web') }
              jobs << "*/#{update_period} * * * * #{File.join(ENV['HOME'], '.iptables-web', 'cron.sh')}"
              crontab.save(jobs)
            end
          end
        end
      end
    end
  end
end
