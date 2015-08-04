require 'yaml'
module IptablesWeb
  class Configuration < Hash
    attr_accessor :loaded
    CONFIG_FILES = %W(#{ENV['HOME']}/.iptables-web/config.yml /etc/iptables-web/config.yml)
    STATIC_RULES_FILES = %W(#{ENV['HOME']}/.iptables-web/static_rules /etc/iptables-web/static_rules)
    CHECKSUM_FILE = "#{ENV['HOME']}/.iptables-web/checksum"

    def initialize
      CONFIG_FILES.each do |config|
        puts "Load configuration from #{config}"
        if load(config)
          @loaded = true
          break
        end
      end
    end

    def load(config)
      clear
      merge! YAML.load File.read(config) if File.exist?(config)
    end

    def self.static_rules
      rules = STATIC_RULES_FILES.map do |file|
        File.exist?(file) ? File.read(file) : nil
      end.compact.join("\n").strip
      chains = rules.scan(/\*([a-z]+)(.*?)COMMIT/m)
      if chains && chains.size > 0
        chains.each_with_object({}) do |r, obj|
          chain = r[0]
          obj[chain] ||= []
          obj[chain] = obj[chain] | r[1].split("\n")
        end
      else
        { 'filter' => rules.split("\n") }
      end
    end

    def self.checksum?(checksum)
      File.exists?(CHECKSUM_FILE) && File.read(CHECKSUM_FILE) == checksum
    end

    def self.checksum=(checksum)
      File.write(CHECKSUM_FILE, checksum)
    end

    def self.config_dir
      File.join(ENV['HOME'], '.iptables-web')
    end
  end
end
