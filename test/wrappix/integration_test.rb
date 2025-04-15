# test/wrappix/integration_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"
require "webmock/minitest"

class IntegrationTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.reset!
  end

  def test_full_api_client_usage
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("integration_config.yml", {
          "api_name" => "integration-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "api_key",
          "api_key_header" => "X-API-Key",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "list", "path" => "users" },
                { "name" => "get", "path" => "users/{id}" },
                { "name" => "create", "path" => "users", "method" => "post" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("integration_config.yml")

        $LOAD_PATH.unshift "#{dir}/lib"
        require "integration_api"

        IntegrationApi.configure do |config|
          config.base_url = "https://api.example.com"
          config.api_key = "test_api_key"
        end

        stub_request(:any, /api\.example\.com/)
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: {
              "data" => [
                { "id" => 1, "name" => "User 1" },
                { "id" => 2, "name" => "User 2" }
              ]
            }.to_json
          )

        client = IntegrationApi.client
        assert_respond_to client, :users
        assert_respond_to client.users, :list
        assert_respond_to client.users, :get
        assert_respond_to client.users, :create
      end
    end
  end
end
