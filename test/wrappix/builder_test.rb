# frozen_string_literal: true

# test/wrappix/builder_test.rb
require "test_helper"
require "tmpdir"
require "yaml"
require "wrappix/builder"

class BuilderTest < Minitest::Test
  def test_builds_basic_files_from_config
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("config.yml", {
          "api_name" => "test-api",
          "base_url" => "https://api.example.com"
        }.to_yaml)

        builder = Wrappix::Builder.new("config.yml")
        builder.build

        # Verificar archivos con nombres normalizados (guiones bajos)
        assert File.exist?("lib/test_api/configuration.rb"), "Missing configuration.rb"
        assert File.exist?("lib/test_api/client.rb"), "Missing client.rb"
        assert File.exist?("lib/test_api/request.rb"), "Missing request.rb"
        assert File.exist?("lib/test_api/error.rb"), "Missing error.rb"
        assert File.exist?("lib/test_api.rb"), "Missing main file"
      end
    end
  end

  def test_builds_resource_files
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Crear archivo de configuración con recursos
        File.write("config.yml", {
          "api_name" => "test-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "list", "method" => "get", "path" => "users" },
                { "name" => "get", "method" => "get", "path" => "users/{id}" }
              ]
            }
          }
        }.to_yaml)

        builder = Wrappix::Builder.new("config.yml")
        builder.build

        # Verificar archivos con nombres normalizados (guiones bajos)
        assert File.exist?("lib/test_api/resources/users.rb"), "Missing resources/users.rb"

        content = File.read("lib/test_api/resources/users.rb")
        assert_match(/def list/, content)
        assert_match(/def get\(id/, content)
      end
    end
  end

  def test_generates_configuration_with_auth_options
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Crear configuración con autenticación OAuth
        File.write("config_oauth.yml", {
          "api_name" => "oauth-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "oauth",
          "token_url" => "https://auth.example.com/token"
        }.to_yaml)

        builder = Wrappix::Builder.new("config_oauth.yml")
        builder.build

        # Verificar contenido de configuración OAuth (con nombres normalizados)
        assert File.exist?("lib/oauth_api/configuration.rb"), "Missing oauth_api/configuration.rb"
        content = File.read("lib/oauth_api/configuration.rb")
        assert_match(/attr_accessor :client_id, :client_secret, :token_url, :access_token/, content)
        assert_match(%r{@token_url = "https://auth.example.com/token"}, content)

        # Crear configuración con autenticación API Key
        File.write("config_apikey.yml", {
          "api_name" => "apikey-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "api_key",
          "api_key_header" => "X-Custom-Key"
        }.to_yaml)

        builder = Wrappix::Builder.new("config_apikey.yml")
        builder.build

        # Verificar contenido de configuración API Key (con nombres normalizados)
        assert File.exist?("lib/apikey_api/configuration.rb"), "Missing apikey_api/configuration.rb"
        content = File.read("lib/apikey_api/configuration.rb")
        assert_match(/attr_accessor :api_key, :api_key_header/, content)
        assert_match(/@api_key_header = "X-Custom-Key"/, content)
      end
    end
  end

  # ... resto de los tests modificados para usar nombres normalizados ...

  def test_main_file_includes_resource_requires
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Configuración con múltiples recursos
        File.write("multi_api.yml", {
          "api_name" => "multi-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [{ "name" => "list", "path" => "users" }]
            },
            "posts" => {
              "endpoints" => [{ "name" => "list", "path" => "posts" }]
            },
            "comments" => {
              "endpoints" => [{ "name" => "list", "path" => "comments" }]
            }
          }
        }.to_yaml)

        # Usar directamente la clase Builder en lugar del método Wrappix.build
        builder = Wrappix::Builder.new("multi_api.yml")
        builder.build

        # Verificar que se crearon los archivos (con nombres normalizados)
        assert File.exist?("lib/multi_api.rb"), "El archivo principal no se creó"

        if File.exist?("lib/multi_api.rb")
          main_content = File.read("lib/multi_api.rb")

          # Verificar que hay referencias a los recursos
          assert_includes main_content, "# Resources"

          # Verificar referencias de recursos en formato normalizado
          assert_match(%r{require_relative "multi_api/resources/users"}, main_content)
          assert_match(%r{require_relative "multi_api/resources/posts"}, main_content)
          assert_match(%r{require_relative "multi_api/resources/comments"}, main_content)
        end
      end
    end
  end

  # ... resto del código de prueba ...
end
