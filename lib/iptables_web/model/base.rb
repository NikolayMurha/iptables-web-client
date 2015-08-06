require 'active_resource'
require 'active_resource_response'

module IptablesWeb
  module Model
    class Base < ActiveResource::Base
      add_response_method :response
      class << self
        def api_base_url=(api_base_url)
          self.site = "#{api_base_url}/api"
        end

        def access_token=(access_token)
          self.headers['X-Node-Access-Token'] = access_token
        end
      end
    end
  end
end
