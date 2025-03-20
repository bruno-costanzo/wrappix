# frozen_string_literal: true

module Wrappix
  module Templates
    class Request
      def self.render(module_name, config)
        <<~RUBY
          # frozen_string_literal: true

          require "faraday"
          require "json"

          module #{module_name}
            class Request
              def initialize(path, config = #{module_name}.configuration)
                @path = path
                @config = config
                @base_url = config.base_url
              end

              def get(params: {}, headers: {})
                make_request(:get, params: params, headers: headers)
              end

              def post(body: {}, headers: {})
                make_request(:post, body: body, headers: headers)
              end

              def put(body: {}, headers: {})
                make_request(:put, body: body, headers: headers)
              end

              def patch(body: {}, headers: {})
                make_request(:patch, body: body, headers: headers)
              end

              def delete(params: {}, headers: {})
                make_request(:delete, params: params, headers: headers)
              end

              private

              def make_request(method, params: {}, body: nil, headers: {})
                response = connection.public_send(method) do |req|
                  req.url @path
                  req.params = params if params && !params.empty?
                  req.body = body.to_json if body && !body.empty?
                  req.headers.merge!(headers) if headers && !headers.empty?
                  req.options.timeout = @config.timeout
                end

                handle_response(response)
              end

              def connection
                @connection ||= Faraday.new(url: @base_url) do |conn|
                  #{connection_auth_config(config)}
                  conn.headers = @config.headers
                  conn.response :json, content_type: /\\bjson$/
                  conn.adapter Faraday.default_adapter
                end
              end

              def handle_response(response)
                return response.body if response.status.between?(200, 299)

                error_message = if response.body.is_a?(Hash)
                                response.body["message"] || response.body["error"] || "Error \#{response.status}"
                              else
                                "Error \#{response.status}"
                              end

                raise #{module_name}::Error.new(error_message, response.body, response.status)
              end
            end
          end
        RUBY
      end

      def self.connection_auth_config(config)
        case config["auth_type"]
        when "oauth"
          "conn.request :authorization, 'Bearer', @config.access_token if @config.access_token"
        when "basic"
          "conn.basic_auth(@config.username, @config.password) if @config.username && @config.password"
        when "api_key"
          "conn.headers[@config.api_key_header] = @config.api_key if @config.api_key"
        else
          ""
        end
      end
    end
  end
end
