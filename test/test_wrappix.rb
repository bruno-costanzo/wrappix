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

        assert File.exist?("lib/simple-api/configuration.rb")
        assert File.exist?("lib/simple-api/client.rb")
        assert File.exist?("lib/simple-api.rb")
      end
    end
  end

  def test_full_api_wrapper_generation_and_usage
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("complete_api.yml", {
          "api_name" => "example-api",
          "base_url" => "https://api.example.com",
          "auth_type" => "api_key",
          "api_key_header" => "X-API-Key",
          "resources" => {
            "users" => {
              "endpoints" => [
                {"name" => "list", "method" => "get", "path" => "users"},
                {"name" => "get", "method" => "get", "path" => "users/{id}"},
                {"name" => "create", "method" => "post", "path" => "users"}
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("complete_api.yml")

        assert File.exist?("lib/example-api.rb")
        assert File.exist?("lib/example-api/configuration.rb")
        assert File.exist?("lib/example-api/client.rb")
        assert File.exist?("lib/example-api/request.rb")
        assert File.exist?("lib/example-api/error.rb")
        assert File.exist?("lib/example-api/resources/users.rb")

        main_content = File.read("lib/example-api.rb")
        assert_match(/require_relative "example-api\/resources\/users"/, main_content)

        resource_content = File.read("lib/example-api/resources/users.rb")
        assert_match(/def list/, resource_content)
        assert_match(/def get\(id\)/, resource_content)
        assert_match(/def create/, resource_content)
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
                {"name" => "get", "method" => "get", "path" => "users/{id}"},
                {"name" => "list", "method" => "get", "path" => "users"}
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("objects_api.yml")

        resource = File.read("lib/objects-api/resources/users.rb")

        get_method = resource.match(/def get.*?end/m)[0]
        assert_match(/Object\.new\(response\)/, get_method)

        list_method = resource.match(/def list.*?end/m)[0]
        assert_match(/Collection\.from_response\(response, type: ObjectsApi::Object\)/, list_method)
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

        # Verificar que se creó el archivo de caché
        assert File.exist?("lib/cache-api/cache.rb")

        # Verificar que el módulo principal tiene configuración de caché
        main_content = File.read("lib/cache-api.rb")
        assert_match(/attr_accessor :configuration, :cache/, main_content)
        assert_match(/self\.cache = MemoryCache\.new/, main_content)

        # Verificar que el Request usa la caché para tokens OAuth
        request_content = File.read("lib/cache-api/request.rb")
        assert_match(/def get_access_token/, request_content)
        assert_match(/token = CacheApi\.cache\.read\("access_token"\)/, request_content)
        assert_match(/CacheApi\.cache\.write\("access_token", token\)/, request_content)
      end
    end
  end
end
