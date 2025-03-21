# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/configuration"

class ConfigurationTemplateTest < Minitest::Test
  def test_default_values
    config = {}
    content = Wrappix::Templates::Configuration.render("TestApi", config)

    assert_match(%r{@base_url = "https://api\.example\.com"}, content)
    assert_match(/@timeout = 30/, content)
    assert_match(%r{"Content-Type" => "application/json"}, content)
    assert_match(%r{"Accept" => "application/json"}, content)
  end

  def test_custom_base_url
    config = { "base_url" => "https://custom-api.com/v2" }
    content = Wrappix::Templates::Configuration.render("TestApi", config)

    assert_match(%r{@base_url = "https://custom-api\.com/v2"}, content)
  end

  def test_oauth_config
    config = {
      "auth_type" => "oauth",
      "token_url" => "https://auth.custom-api.com/token"
    }
    content = Wrappix::Templates::Configuration.render("TestApi", config)

    assert_match(/attr_accessor :client_id, :client_secret, :token_url, :access_token/, content)
    assert_match(%r{@token_url = "https://auth\.custom-api\.com/token"}, content)
    assert_match(/@client_id = nil/, content)
    assert_match(/@client_secret = nil/, content)
    assert_match(/@access_token = nil/, content)
  end

  def test_api_key_config
    config = {
      "auth_type" => "api_key",
      "api_key_header" => "X-Custom-Auth"
    }
    content = Wrappix::Templates::Configuration.render("TestApi", config)

    assert_match(/attr_accessor :api_key, :api_key_header/, content)
    assert_match(/@api_key = nil/, content)
    assert_match(/@api_key_header = "X-Custom-Auth"/, content)
  end
end
