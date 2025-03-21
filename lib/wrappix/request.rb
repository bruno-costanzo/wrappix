# frozen_string_literal: true

module Wrappix
  class Request
    def initialize(url, config = Wrappix.configuration)
      @url = url
      @config = config
    end

    def get(params: {}, headers: {})
      handle_response connection.get(@url, params, headers)
    end

    def post(body: {}, headers: {})
      handle_response connection.post(@url, body, headers)
    end

    def patch(body: {}, headers: {})
      handle_response connection.patch(@url, body, headers)
    end

    def put(body: {}, headers: {})
      handle_response connection.put(@url, body, headers)
    end

    def delete(params: {}, headers: {})
      handle_response connection.delete(@url, params, headers)
    end

    private

    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = @config.base_url

        # Configurar autenticación según el tipo
        case @config.auth_type
        when :oauth
          conn.request :authorization, :Bearer, @config.access_token
        when :basic
          conn.basic_auth(@config.username, @config.password)
        when :api_key
          conn.headers[@config.api_key_header] = @config.api_key
        end

        conn.request :json
        conn.response :json, content_type: "application/json", parser_options: { symbolize_names: true }
        conn.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      return response if response.status.between?(200, 299)

      error_message = if response.body.is_a?(Hash)
                        response.body[:message] || response.body[:error] || "Error #{response.status}"
                      else
                        "Error #{response.status}"
                      end

      raise Wrappix::Error.new(error_message, response.body, response.status)
    end
  end

  class Error < StandardError
    attr_reader :body, :status

    def initialize(message, body = nil, status = nil)
      @body = body
      @status = status
      super(message)
    end
  end
end
