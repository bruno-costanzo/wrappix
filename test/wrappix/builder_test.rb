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

  def test_resource_methods_generate_correctly
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Configuración con parámetros correctos
        File.write("params_api.yml", {
          "api_name" => "params-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                {
                  "name" => "create",
                  "method" => "post",
                  "path" => "users"
                },
                {
                  "name" => "update",
                  "method" => "put",
                  "path" => "users/{id}"
                },
                {
                  "name" => "list",
                  "method" => "get",
                  "path" => "users",
                  "params" => true
                }
              ]
            }
          }
        }.to_yaml)

        # Generar el wrapper
        Wrappix.build("params_api.yml")

        # Verificar que los métodos aceptan los parámetros correctos
        resource = File.read("lib/params-api/resources/users.rb")

        # POST sin parámetros en path debe aceptar cuerpo
        assert_match(/def create\(body = {}\)/, resource)
        assert_match(/request\.post\(body: body\)/, resource)

        # PUT con id en path debe aceptar id y cuerpo
        assert_match(/def update\(id, body = {}\)/, resource)
        assert_match(/request\.put\(body: body\)/, resource)

        # GET con params debe aceptar parámetros de consulta
        assert_match(/def list\(params = {}\)/, resource)
        assert_match(/request\.get\(params: params\)/, resource)
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
        # Configuración con múltiples recursos
        File.write("multi_api.yml", {
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

        # Usar directamente la clase Builder en lugar del método Wrappix.build
        builder = Wrappix::Builder.new("multi_api.yml")
        builder.build

        # Verificar que se crearon los archivos
        assert File.exist?("lib/multi-api.rb"), "El archivo principal no se creó"

        if File.exist?("lib/multi-api.rb")
          main_content = File.read("lib/multi-api.rb")

          # Verificar que hay referencias a los recursos
          assert_includes main_content, "# Resources"

          # Verificar el formato actual que estás utilizando para los requires
          if main_content.include?("require_relative \"multi-api/resources/")
            assert_match(/require_relative "multi-api\/resources\/users"/, main_content)
            assert_match(/require_relative "multi-api\/resources\/posts"/, main_content)
            assert_match(/require_relative "multi-api\/resources\/comments"/, main_content)
          else
            assert_match(/require_relative "multi-api\/user"/, main_content)
            assert_match(/require_relative "multi-api\/post"/, main_content)
            assert_match(/require_relative "multi-api\/comment"/, main_content)
          end
        end
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
        assert File.exist?("lib/changing-api.rb"), "El archivo principal no se creó"

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
        assert File.exist?("lib/changing-api.rb"), "El archivo principal no se creó en la segunda generación"

        if File.exist?("lib/changing-api.rb")
          main_content = File.read("lib/changing-api.rb")

          # Comprobar la estructura actual (resources/ o archivos individuales)
          if main_content.include?("require_relative \"changing-api/resources/")
            assert_match(/require_relative "changing-api\/resources\/posts"/, main_content)
            refute_match(/require_relative "changing-api\/resources\/users"/, main_content)
          else
            assert_match(/require_relative "changing-api\/post"/, main_content)
            refute_match(/require_relative "changing-api\/user"/, main_content)
          end
        end
      end
    end
  end
end
