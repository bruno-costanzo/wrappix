# frozen_string_literal: true

module Wrappix
  module Templates
    class Configuration
      def self.render(module_name, config)
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            class Configuration
              attr_accessor :base_url, :timeout, :headers
              #{auth_config_attributes(config)}

              def initialize
                @base_url = "#{config["base_url"] || "https://api.example.com"}"
                @timeout = 30
                @headers = {
                  "Content-Type" => "application/json",
                  "Accept" => "application/json"
                }
                #{auth_config_initialization(config)}
              end
            end
          end
        RUBY
      end

      def self.auth_config_attributes(config)
        case config["auth_type"]
        when "oauth"
          "attr_accessor :client_id, :client_secret, :token_url, :access_token"
        when "basic"
          "attr_accessor :username, :password"
        when "api_key"
          "attr_accessor :api_key, :api_key_header"
        else
          ""
        end
      end

      def self.auth_config_initialization(config)
        case config["auth_type"]
        when "oauth"
          <<~RUBY.strip
            @client_id = nil
            @client_secret = nil
            @token_url = "#{config["token_url"] || "https://api.example.com/oauth/token"}"
            @access_token = nil
          RUBY
        when "basic"
          <<~RUBY.strip
            @username = nil
            @password = nil
          RUBY
        when "api_key"
          <<~RUBY.strip
            @api_key = nil
            @api_key_header = "#{config["api_key_header"] || "X-Api-Key"}"
          RUBY
        else
          ""
        end
      end
    end
  end
end
