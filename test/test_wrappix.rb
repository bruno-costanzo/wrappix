# frozen_string_literal: true

require "test_helper"

class TestWrappix < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Wrappix::VERSION
  end

  def test_build_method_creates_files
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("simple_config.yml", {
          "api_name" => "simple-api",
          "base_url" => "https://simple.example.com"
        }.to_yaml)

        Wrappix.build("simple_config.yml")

        # Verificar archivos con nombres normalizados (guiones bajos)
        assert File.exist?("lib/simple_api/configuration.rb"), "Missing configuration.rb"
        assert File.exist?("lib/simple_api/client.rb"), "Missing client.rb"
        assert File.exist?("lib/simple_api.rb"), "Missing main file"
      end
    end
  end

  def test_full_api_wrapper_generation_and_usage
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # 1. Crear un archivo de configuración completo
        File.write("complete_api.yml", {
          "api_name" => "example-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "api_key",
          "api_key_header" => "X-API-Key",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "list", "method" => "get", "path" => "users" },
                { "name" => "get", "method" => "get", "path" => "users/{id}" },
                { "name" => "create", "method" => "post", "path" => "users" }
              ]
            }
          }
        }.to_yaml)

        # 2. Generar el wrapper con el builder
        builder = Wrappix::Builder.new("complete_api.yml")
        builder.build

        # 3. Verificar que se crearon todos los archivos necesarios (con guiones bajos)
        assert File.exist?("lib/example_api.rb"), "El archivo principal no se creó"
        assert File.exist?("lib/example_api/configuration.rb"), "El archivo de configuración no se creó"

        # Solo verificar el archivo principal si existe
        if File.exist?("lib/example_api.rb")
          main_content = File.read("lib/example_api.rb")

          # Adaptarse a la estructura actual (resources/)
          assert_match(%r{require_relative "example_api/resources/users"}, main_content)
        end
      end
    end
  end

  def test_endpoints_return_proper_objects
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("objects_api.yml", {
          "api_name" => "objects-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "get", "method" => "get", "path" => "users/{id}" },
                { "name" => "list", "method" => "get", "path" => "users" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("objects_api.yml")

        # Verificar archivos con nombres normalizados (guiones bajos)
        assert File.exist?("lib/objects_api/resources/users.rb"), "El archivo de recursos users.rb no se creó"

        resource = File.read("lib/objects_api/resources/users.rb")

        get_method = resource.match(/def get.*?end/m)
        assert get_method, "Método get no encontrado"
        assert_match(/Object\.new\(response\)/, get_method[0])

        list_method = resource.match(/def list.*?end/m)
        assert list_method, "Método list no encontrado"
        assert_match(/Collection\.from_response\(response, type: ObjectsApi::Object\)/, list_method[0])
      end
    end
  end

  def test_cache_implementation
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("cache_api.yml", {
          "api_name" => "cache-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "oauth"
        }.to_yaml)

        Wrappix.build("cache_api.yml")

        # Verificar que se creó el archivo de caché con nombre normalizado
        assert File.exist?("lib/cache_api/cache.rb"), "El archivo cache.rb no se creó"

        # Verificar que el módulo principal tiene configuración de caché
        assert File.exist?("lib/cache_api.rb"), "El archivo principal no se creó"
        main_content = File.read("lib/cache_api.rb")
        assert_match(/attr_accessor :configuration, :cache/, main_content)
        assert_match(/self\.cache = MemoryCache\.new/, main_content)

        # Verificar que el Request usa la caché para tokens OAuth
        request_content = File.read("lib/cache_api/request.rb")
        assert_match(/def get_access_token/, request_content)
        assert_match(/token = CacheApi\.cache\.read\("access_token"\)/, request_content)
        assert_match(/CacheApi\.cache\.write\("access_token", token\)/, request_content)
      end
    end
  end
end
