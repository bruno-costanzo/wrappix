# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/client"

class ClientTemplateTest < Minitest::Test
  def test_generates_client_with_no_resources
    config = {}
    content = Wrappix::Templates::Client.render("TestApi", config)

    assert_match(/module TestApi/, content)
    assert_match(/class Client/, content)
    assert_match(/def initialize\(configuration = TestApi\.configuration\)/, content)
    assert_match(/@configuration = configuration/, content)

    refute_match(/def users/, content)
  end

  def test_generates_client_with_multiple_resources
    config = {
      "resources" => {
        "users" => {},
        "posts" => {},
        "comments" => {}
      }
    }
    content = Wrappix::Templates::Client.render("TestApi", config)

    assert_match(/def users/, content)
    assert_match(/def posts/, content)
    assert_match(/def comments/, content)

    assert_match(/@users \|\|= Resources::Users\.new\(self\)/, content)
    assert_match(/@posts \|\|= Resources::Posts\.new\(self\)/, content)
    assert_match(/@comments \|\|= Resources::Comments\.new\(self\)/, content)
  end
end
