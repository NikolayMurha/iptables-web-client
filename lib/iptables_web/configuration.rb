require 'yaml'
module IptablesWeb
  class Configuration < Hash
    attr_accessor :loaded
    CONFIG_FILES = %W(#{ENV['HOME']}/.iptables-web/config.yml /etc/iptables-web/config.yml)
    STATIC_RULES_FILES = %W(#{ENV['HOME']}/.iptables-web/static_rules /etc/iptables-web/static_rules)

    def initialize
      CONFIG_FILES.each do |config|
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
      rules.scan(/\*([a-z]+)(.*?)COMMIT/m).each_with_object({}) do |r, obj|
        chain = r[0]
        obj[chain] ||= []
        obj[chain]  = obj[chain] | r[1].split("\n")
      end
    end

    def self.config_dir
      File.join(ENV['HOME'], '.iptables-web')
    end
  end
end
