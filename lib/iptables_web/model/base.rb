require 'active_resource'
module IptablesWeb
  module Model
    class Base < ActiveResource::Base
      def self.configure(config)
        self.site = "#{config['api_base_url']}/api"
        headers['X-Node-Access-Token'] = config['access_token']
      end
    end
  end
end