require 'active_resource'
require 'active_resource_response'

module IptablesWeb
  module Model
    class Base < ActiveResource::Base
      add_response_method :response
      def self.configure(config)
        self.site = "#{config['api_base_url']}/api"
        headers['X-Node-Access-Token'] = config['access_token']
      end
    end
  end
end
