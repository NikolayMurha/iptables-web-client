require 'yaml'
module IptablesWeb
  module Configuration
    include IptablesWeb::Mixin::ConfigParser

    def reload
      if File.exists?(config_path)
        logged_say("Load config file #{config_path}")
        YAML.load_file(config_path).each do |method, value|
          send("#{method}=".to_sym, value)
        end
      else
        logged_say("Config file #{config_path} does not exist")
      end
    end

    def static_rules
      return {} unless static_rules?
      rules = File.read(static_rules_path)
      parse_rules(rules)
    end

    def static_rules?
      File.exist?(static_rules_path)
    end

    def home
      @home || ENV['HOME']
    end

    def home=(home)
      @home = home
    end

    def dir
      @dir ||= begin
        if root?
          '/var/run/iptables_web'
        else
          File.expand_path(File.join(home, '.iptables-web'))
        end
      end
    end

    def dir=(d)
      @dir = d
    end

    def path(path)
      File.expand_path(path, dir)
    end

    def root?
      Process::UID.eid == 0
    end

    #
    def config_path
      if root?
        '/etc/iptables_web/config.yml'
      else
        path(@config_path || 'config.yml')
      end
    end

    def config_path=(config_path)
      @config_path = config_path
    end

    #
    def pid_path
      path(@pid_path || 'run.pid')
    end

    def pid_path=(pid_path)
      @pid_path = pid_path
    end

    #
    def log_path
      if root?
        '/var/log/iptables-web.log'
      else
        path(@log_path || 'run.log')
      end
    end

    def log_path=(pid_path)
      @log_path = pid_path
      $terminal.reset if $terminal.present? && $terminal.is_a?(Cli::LoggedOutput)
    end

    def log_level=(level)
      @log_level = level
      $terminal.log_level=level if $terminal.present? && $terminal.is_a?(Cli::LoggedOutput)
    end

    def log_level
      @log_level || ::Logger::INFO
    end

    def checksum_path
      path(@checksum_path || 'checksum')
    end

    def checksum
      File.read(checksum_path) if File.exists?(checksum_path)
    end

    def checksum_path=(pid_path)
      @checksum_path = pid_path
    end


    def checksum?(etag)
      checksum == make_checksum(etag)
    end

    def checksum=(etag)
      File.write(checksum_path, make_checksum(etag))
    end

    def make_checksum(check_sum)
      check_sum = check_sum.to_s
      check_sum += Digest::MD5.file(static_rules_path).hexdigest if static_rules?
      Digest::MD5.hexdigest(check_sum)
    end

    #
    def static_rules_path
      if root?
        '/etc/iptables_web/static_rules'
      else
        path(@static_rules_path || 'static_rules')
      end
    end

    def static_rules_path=(static_rules_path)
      @static_rules_path = static_rules_path
    end

    #
    def api_base_url
      # raise 'api_base_url is required' unless @api_base_url
      @api_base_url
    end

    def api_base_url=(api_base_url)
      @api_base_url = api_base_url
      IptablesWeb::Model::Base.api_base_url = api_base_url
    end

    def access_token
      raise 'Access_token is required' unless @access_token
      @access_token
    end

    def access_token=(access_token)
      @access_token = access_token
      IptablesWeb::Model::Base.access_token = access_token
    end

    def pid_file(&block)
      pid_file = Cli::PidFile.new(pid_path)
      begin
        pid_file.create
        block.call(pid_file)
        pid_file.delete
      rescue Cli::PidFile::AnotherLaunched => e

        pid_file.delete
        logged_say(e.message)
        return
      rescue Exception => e
        pid_file.delete
        raise e
      end
    end
  end
end
