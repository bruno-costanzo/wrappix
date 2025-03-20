require "test_helper"
require "wrappix/templates/main"

class MainTemplateTest < Minitest::Test
  def test_generates_main_file_with_proper_requires
    config = {}
    content = Wrappix::Templates::Main.render("test-api", "TestApi", config)

    assert_match(/require_relative "test-api\/version"/, content)
    assert_match(/require_relative "test-api\/configuration"/, content)
    assert_match(/require_relative "test-api\/error"/, content)
    assert_match(/require_relative "test-api\/request"/, content)
    assert_match(/require_relative "test-api\/client"/, content)

    assert_match(/module TestApi/, content)
    assert_match(/class << self/, content)
    assert_match(/attr_accessor :configuration/, content)
    assert_match(/def configure/, content)
    assert_match(/yield\(configuration\) if block_given\?/, content)
    assert_match(/def client/, content)
    assert_match(/@client \|\|= Client\.new\(configuration\)/, content)
    assert_match(/self\.configuration = Configuration\.new/, content)
  end

  def test_includes_resource_requires
    config = {
      "resources" => {
        "users" => {},
        "posts" => {},
        "comments" => {}
      }
    }
    content = Wrappix::Templates::Main.render("test-api", "TestApi", config)

    assert_match(/require_relative "test-api\/resources\/users"/, content)
    assert_match(/require_relative "test-api\/resources\/posts"/, content)
    assert_match(/require_relative "test-api\/resources\/comments"/, content)
  end
end
