require 'commander'

module IptablesWeb
  class Cli
    attr_reader :output
    include ::Commander::Methods
    include IptablesWeb::Cli::Command::Install
    include IptablesWeb::Cli::Command::Update

    def initialize
      program :name, 'Iptables Web Client'
      program :version, IptablesWeb::VERSION
      program :description, 'Desc'
      default_command :update

      global_option('--config FILE', 'Configuration file') do |config|
        IptablesWeb.config_path = config
        IptablesWeb.reload
      end

      global_option('--verbose', 'Combination of --log-level debug and --log-stdout') do |_|
        IptablesWeb.log_level = ::Logger::INFO
        IptablesWeb.log_stdout
      end

      global_option('--log-file FILE', 'Log file path') do |log_path|
        IptablesWeb.log_path = log_path
      end

      global_option('--log-level LEVEL', 'Log level') do |log_level|
        IptablesWeb.log_level = log_level
      end

      global_option('--log-stdout', 'Write log to stdout too') do |log_level|
        IptablesWeb.log_stdout = log_level
      end

      global_option('--host URL', 'Server base url') do |server_base_url|
        IptablesWeb.api_base_url = server_base_url
      end

      global_option('--token TOKEN', 'Server base url') do |access_token|
        IptablesWeb.access_token = access_token
      end

      install_command
      update_command
      run!
    end
  end
end
