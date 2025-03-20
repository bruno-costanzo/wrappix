require "test_helper"
require "wrappix/templates/readme"

class ReadmeTemplateTest < Minitest::Test
  def test_generates_basic_readme
    config = {
      "base_url" => "https://api.example.com",
      "resources" => {
        "users" => {
          "endpoints" => [
            {"name" => "list", "method" => "get", "path" => "users"},
            {"name" => "get", "method" => "get", "path" => "users/{id}"}
          ]
        }
      }
    }

    content = Wrappix::Templates::Readme.render("test-api", "TestApi", config)

    # Check basic sections
    assert_match(/# TestApi API Client/, content)
    assert_match(/## Installation/, content)
    assert_match(/## Configuration/, content)
    assert_match(/## Usage/, content)
    assert_match(/## Available Resources and Endpoints/, content)

    # Check resource documentation
    assert_match(/### Users/, content)
    assert_match(/#### `list`/, content)
    assert_match(/#### `get`/, content)
    assert_match(/- HTTP Method: `GET`/, content)
    assert_match(/- Path: `users\/{id}`/, content)
    assert_match(/- Path Parameters: `id`/, content)

    # Check usage examples
    assert_match(/client\.users\.list/, content)
    assert_match(/client\.users\.get\(/, content)
  end

  def test_includes_auth_instructions
    # OAuth
    oauth_config = {"auth_type" => "oauth"}
    oauth_content = Wrappix::Templates::Readme.render("oauth-api", "OauthApi", oauth_config)
    assert_match(/config\.client_id = "your_client_id"/, oauth_content)
    assert_match(/config\.client_secret = "your_client_secret"/, oauth_content)

    # Basic Auth
    basic_config = {"auth_type" => "basic"}
    basic_content = Wrappix::Templates::Readme.render("basic-api", "BasicApi", basic_config)
    assert_match(/config\.username = "your_username"/, basic_content)
    assert_match(/config\.password = "your_password"/, basic_content)

    # API Key
    apikey_config = {"auth_type" => "api_key", "api_key_header" => "X-Custom-Key"}
    apikey_content = Wrappix::Templates::Readme.render("apikey-api", "ApikeyApi", apikey_config)
    assert_match(/config\.api_key = "your_api_key"/, apikey_content)
    assert_match(/config\.api_key_header = "X-Custom-Key"/, apikey_content)
  end
end
