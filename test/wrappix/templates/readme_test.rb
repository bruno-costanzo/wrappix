# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/readme"

class ReadmeTemplateTest < Minitest::Test
  def test_generates_basic_readme
    config = {
      "base_url" => "https://api.example.com",
      "resources" => {
        "users" => {
          "endpoints" => [
            { "name" => "list", "method" => "get", "path" => "users" },
            { "name" => "get", "method" => "get", "path" => "users/{id}" }
          ]
        }
      }
    }

    content = Wrappix::Templates::Readme.render("test-api", "TestApi", config)

    # Verificar secciones principales
    assert_includes content, "TestApi API Client"
    assert_includes content, "Installation"
    assert_includes content, "Configuration"
    assert_includes content, "Usage"
    assert_includes content, "Error Handling"

    # Verificar recursos
    assert_includes content, "Users"
    assert_includes content, "list"
    assert_includes content, "get"
    assert_includes content, "HTTP Method: `GET`"
    assert_includes content, "Path: `users/{id}`"
    assert_includes content, "Path Parameters: `id`"

    # Verificar ejemplos de uso
    assert_includes content, "client.users.list"
    assert_includes content, "client.users.get"

    # Verificar que hay instrucciones de instalación
    assert_includes content, "gem 'test-api'"
    assert_includes content, "bundle install"
    assert_includes content, "gem install test-api"
  end

  def test_includes_auth_instructions
    # OAuth
    oauth_config = { "auth_type" => "oauth" }
    oauth_content = Wrappix::Templates::Readme.render("oauth-api", "OauthApi", oauth_config)
    assert_match(/config\.client_id = "your_client_id"/, oauth_content)
    assert_match(/config\.client_secret = "your_client_secret"/, oauth_content)

    # Basic Auth
    basic_config = { "auth_type" => "basic" }
    basic_content = Wrappix::Templates::Readme.render("basic-api", "BasicApi", basic_config)
    assert_match(/config\.username = "your_username"/, basic_content)
    assert_match(/config\.password = "your_password"/, basic_content)

    # API Key
    apikey_config = { "auth_type" => "api_key", "api_key_header" => "X-Custom-Key" }
    apikey_content = Wrappix::Templates::Readme.render("apikey-api", "ApikeyApi", apikey_config)
    assert_match(/config\.api_key = "your_api_key"/, apikey_content)
    assert_match(/config\.api_key_header = "X-Custom-Key"/, apikey_content)
  end
end
