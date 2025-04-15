# frozen_string_literal: true

module Wrappix
  module Templates
    class Request
      def self.render(module_name, config)
        oauth_token_logic = if config["auth_type"] == "oauth"
                              <<~RUBY
                                def get_access_token
                                  # Try to get token from cache first
                                  token = #{module_name}.cache.read("access_token")
                                  return token if token

                                  # If not in cache, fetch new token
                                  response = Faraday.post(@config.token_url, {
                                    client_id: @config.client_id,
                                    client_secret: @config.client_secret,
                                    grant_type: "client_credentials"
                                  })

                                  if response.status == 200
                                    data = JSON.parse(response.body)
                                    token = data["access_token"]
                                    expires_in = data["expires_in"] || 3600

                                    # Cache the token
                                    #{module_name}.cache.write("access_token", token)

                                    # Cache expiration handling could be improved
                                    token
                                  else
                                    raise #{module_name}::Error.new("Failed to obtain access token", response.body, response.status)
                                  end
                                end
                              RUBY
                            else
                              ""
                            end

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
                  conn.headers = @config.headers
                  #{connection_auth_config(config)}
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

              #{oauth_token_logic}
            end
          end
        RUBY
      end

      def self.connection_auth_config(config)
        case config["auth_type"]
        when "oauth"
          "conn.request :authorization, 'Bearer', get_access_token if @config.client_id && @config.client_secret"
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
