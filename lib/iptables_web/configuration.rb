require 'yaml'
require 'fileutils'
module IptablesWeb
  module Configuration
    include IptablesWeb::Mixin::ConfigParser

    def reload
      if File.exists?(config_path)
        logger_log("Load config file #{config_path}")
        YAML.load_file(config_path).each do |method, value|
          send("#{method}=".to_sym, value)
        end
      else
        logger_log("Config file #{config_path} does not exist")
      end
    end

    def static_rules
      unless static_rules?
        return {
          'filter' => [
            '-A INPUT -i lo -j ACCEPT',
            '-A FORWARD -i lo -j ACCEPT',
            '-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT',
            '-A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT'
          ]
        }
      end
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

    def work_dir
      @work_dir ||= begin
        work_dir = '/tmp/iptables-web'
        FileUtils.mkdir_p(work_dir) unless File.exist?(work_dir)
        work_dir
      end
    end

    def work_dir=(d)
      @work_dir = d
    end

    def work_path(path)
      File.expand_path(path, work_dir)
    end

    def root?
      Process::UID.eid == 0
    end

    def config_path
      @config_path || '/etc/iptables-web/config.yml'
    end

    def config_path=(config_path)
      @config_path = config_path
    end

    #
    def pid_path
      work_path(@pid_path || 'run.pid')
    end

    def pid_path=(pid_path)
      @pid_path = pid_path
    end

    #
    def log_path
      @log_path || '/var/log/iptables-web/run.log'
    end

    def log_path=(pid_path)
      @log_path = pid_path
      $terminal.reset if $terminal.present?
    end

    def log_level=(level)
      $terminal.log_level = level if $terminal.present?
    end

    def log_stdout
      $terminal.log_stdout if $terminal.present?
    end

    def log_level
      $terminal.present? ? $terminal.log_level : ::Logger::INFO
    end

    def checksum_path
      work_path(@checksum_path || 'checksum')
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

    def static_rules_path
      @static_rules_path || File.expand_path('static_rules', File.dirname(config_path))
    end

    def static_rules_path=(static_rules_path)
      @static_rules_path = static_rules_path
    end

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
        logger_log(e.message)
        return
      rescue Exception => e
        pid_file.delete
        raise e
      end
    end
  end
end
