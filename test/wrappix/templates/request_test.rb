require "test_helper"
require "wrappix/templates/request"

class RequestTemplateTest < Minitest::Test
  def test_oauth_authentication
    config = {"auth_type" => "oauth"}
    content = Wrappix::Templates::Request.render("TestApi", config)

    assert_match(/conn\.request :authorization, 'Bearer', @config\.access_token/, content)
  end

  def test_basic_authentication
    config = {"auth_type" => "basic"}
    content = Wrappix::Templates::Request.render("TestApi", config)

    assert_match(/conn\.basic_auth\(@config\.username, @config\.password\)/, content)
  end

  def test_api_key_authentication
    config = {"auth_type" => "api_key"}
    content = Wrappix::Templates::Request.render("TestApi", config)

    assert_match(/conn\.headers\[@config\.api_key_header\] = @config\.api_key/, content)
  end

  def test_no_authentication
    config = {}
    content = Wrappix::Templates::Request.render("TestApi", config)

    refute_match(/conn\.request :authorization/, content)
    refute_match(/conn\.basic_auth/, content)
    refute_match(/conn\.headers\[@config\.api_key_header\]/, content)
  end
end
