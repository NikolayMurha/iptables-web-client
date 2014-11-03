require 'iptables_web/version'
require 'iptables_web/configuration'
require 'iptables_web/mixin/sudo'
require 'iptables_web/model/base'
require 'iptables_web/model/access_rule'
require 'iptables_web/model/node'
require 'iptables_web/crontab'
require 'iptables_web/iptables'

module IptablesWeb
  class << self
    attr_accessor :configuration
    def configuration
      self.configuration = Configuration.new unless @configuration
      @configuration
    end

    def configuration=(config)
      @configuration = config
      IptablesWeb::Model::Base.configure(config)
      @configuration
    end
  end
end

IptablesWeb.configuration =  IptablesWeb::Configuration.new #set default configuration
