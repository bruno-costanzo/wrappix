# frozen_string_literal: true

require "faraday"
require "faraday_middleware"

module Wrappix
  class Client
    def initialize(config = Wrappix.configuration)
      @config = config
      @connection = build_connection
      setup_resources
    end

    private

    def build_connection
      Faraday.new(url: @config.base_url) do |conn|
        conn.headers = @config.headers
        conn.request :json
        conn.response :json, content_type: /\bjson$/
        conn.adapter Faraday.default_adapter
      end
    end

    def setup_resources
      @config.resources.each do |name, options|
        define_resource_method(name, options)
      end
    end

    def define_resource_method(name, options)
      resource = Resource.new(self, name, options)

      self.class.define_method(name) do
        resource
      end
    end
  end
end
