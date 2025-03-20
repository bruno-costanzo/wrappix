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

        assert File.exist?("lib/test-api/configuration.rb")
        assert File.exist?("lib/test-api/client.rb")
        assert File.exist?("lib/test-api/request.rb")
        assert File.exist?("lib/test-api/error.rb")
        assert File.exist?("lib/test-api.rb")
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
                {"name" => "list", "method" => "get", "path" => "users"},
                {"name" => "get", "method" => "get", "path" => "users/{id}"}
              ]
            }
          }
        }.to_yaml)

        builder = Wrappix::Builder.new("config.yml")
        builder.build

        assert File.exist?("lib/test-api/resources/users.rb")

        content = File.read("lib/test-api/resources/users.rb")
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

        # Verificar contenido de configuración OAuth
        content = File.read("lib/oauth-api/configuration.rb")
        assert_match(/attr_accessor :client_id, :client_secret, :token_url, :access_token/, content)
        assert_match(/@token_url = "https:\/\/auth.example.com\/token"/, content)

        # Crear configuración con autenticación API Key
        File.write("config_apikey.yml", {
          "api_name" => "apikey-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "api_key",
          "api_key_header" => "X-Custom-Key"
        }.to_yaml)

        builder = Wrappix::Builder.new("config_apikey.yml")
        builder.build

        # Verificar contenido de configuración API Key
        content = File.read("lib/apikey-api/configuration.rb")
        assert_match(/attr_accessor :api_key, :api_key_header/, content)
        assert_match(/@api_key_header = "X-Custom-Key"/, content)
      end
    end
  end

  def test_updates_existing_files_when_config_changes
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("evolving_api.yml", {
          "api_name" => "evolving-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                {"name" => "list", "method" => "get", "path" => "users"}
              ]
            }
          }
        }.to_yaml)

        builder = Wrappix::Builder.new("evolving_api.yml")
        builder.build

        assert File.exist?("lib/evolving-api/resources/users.rb")
        initial_content = File.read("lib/evolving-api/resources/users.rb")
        assert_match(/def list/, initial_content)
        refute_match(/def create/, initial_content)

        File.write("evolving_api.yml", {
          "api_name" => "evolving-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                {"name" => "list", "method" => "get", "path" => "users"},
                {"name" => "create", "method" => "post", "path" => "users"}
              ]
            }
          }
        }.to_yaml)

        # Segunda generación
        builder = Wrappix::Builder.new("evolving_api.yml")
        builder.build

        # Verificar que se actualizó el archivo
        updated_content = File.read("lib/evolving-api/resources/users.rb")
        assert_match(/def list/, updated_content)
        assert_match(/def create/, updated_content)
      end
    end
  end

  def test_main_file_includes_resource_requires
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("config.yml", {
          "api_name" => "multi-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [{"name" => "list", "path" => "users"}]
            },
            "posts" => {
              "endpoints" => [{"name" => "list", "path" => "posts"}]
            },
            "comments" => {
              "endpoints" => [{"name" => "list", "path" => "comments"}]
            }
          }
        }.to_yaml)

        builder = Wrappix::Builder.new("config.yml")
        builder.build

        content = File.read("lib/multi-api.rb")
        assert_match(/require_relative "multi-api\/resources\/users"/, content)
        assert_match(/require_relative "multi-api\/resources\/posts"/, content)
        assert_match(/require_relative "multi-api\/resources\/comments"/, content)

        assert File.exist?("lib/multi-api/resources/users.rb")
        assert File.exist?("lib/multi-api/resources/posts.rb")
        assert File.exist?("lib/multi-api/resources/comments.rb")
      end
    end
  end

  def test_handles_resource_addition_and_removal
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # 1. Configuración inicial con recurso "users"
        File.write("changing_api.yml", {
          "api_name" => "changing-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [{"name" => "list", "path" => "users"}]
            }
          }
        }.to_yaml)

        # Primera generación
        builder = Wrappix::Builder.new("changing_api.yml")
        builder.build

        # Verificar archivos iniciales
        assert File.exist?("lib/changing-api/resources/users.rb")
        refute File.exist?("lib/changing-api/resources/posts.rb")

        # 2. Modificar configuración (quitar users, añadir posts)
        File.write("changing_api.yml", {
          "api_name" => "changing-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "posts" => {
              "endpoints" => [{"name" => "list", "path" => "posts"}]
            }
          }
        }.to_yaml)

        # Segunda generación
        builder = Wrappix::Builder.new("changing_api.yml")
        builder.build

        # Verificar archivos actualizados
        # El archivo users.rb aún existirá, pero el contenido del archivo principal cambiará
        # para reflejar solo el nuevo recurso
        assert File.exist?("lib/changing-api/resources/posts.rb")

        main_content = File.read("lib/changing-api.rb")
        assert_match(/require_relative "changing-api\/resources\/posts"/, main_content)
        refute_match(/require_relative "changing-api\/resources\/users"/, main_content)

        # Verificar que el cliente ya no tiene el método users
        client_content = File.read("lib/changing-api/client.rb")
        refute_match(/def users/, client_content)
        assert_match(/def posts/, client_content)
      end
    end
  end
end
