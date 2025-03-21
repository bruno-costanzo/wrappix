# test/wrappix/error_handling_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"
require "webmock/minitest"

class ErrorHandlingTest < Minitest::Test
  def setup
    WebMock.disable_net_connect!
  end

  def teardown
    WebMock.reset!
  end

  def test_handles_http_errors
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Configuración básica
        File.write("error_config.yml", {
          "api_name" => "error-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "get", "path" => "users/{id}" }
              ]
            }
          }
        }.to_yaml)

        # Generar la API
        Wrappix.build("error_config.yml")

        # Cargar el código generado
        $LOAD_PATH.unshift "#{dir}/lib"
        require "error_api"

        # Configurar el cliente
        ErrorApi.configure do |config|
          config.base_url = "https://api.example.com"
        end

        # Mockear diferentes respuestas de error - permitir cualquier header

        # 1. Error 404
        stub_request(:get, "https://api.example.com/users/999")
          .to_return(
            status: 404,
            headers: { "Content-Type" => "application/json" },
            body: { error: "User not found" }.to_json
          )

        # 2. Error 401
        stub_request(:get, "https://api.example.com/users/unauthorized")
          .to_return(
            status: 401,
            headers: { "Content-Type" => "application/json" },
            body: { error: "Unauthorized access" }.to_json
          )

        # 3. Error 500
        stub_request(:get, "https://api.example.com/users/server-error")
          .to_return(
            status: 500,
            headers: { "Content-Type" => "application/json" },
            body: { error: "Internal server error" }.to_json
          )

        # Probar el cliente
        client = ErrorApi.client

        # Probar error 404
        error = assert_raises(ErrorApi::Error) do
          client.users.get(999)
        end
        assert_equal 404, error.status
        assert_match(/User not found/, error.message)

        # Probar error 401
        error = assert_raises(ErrorApi::Error) do
          client.users.get("unauthorized")
        end
        assert_equal 401, error.status
        assert_match(/Unauthorized access/, error.message)

        # Probar error 500
        error = assert_raises(ErrorApi::Error) do
          client.users.get("server-error")
        end
        assert_equal 500, error.status
        assert_match(/Internal server error/, error.message)
      end
    end
  end
end
