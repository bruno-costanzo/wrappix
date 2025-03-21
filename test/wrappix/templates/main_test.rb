# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/main"

class MainTemplateTest < Minitest::Test
  def test_generates_main_file_with_proper_requires
    config = {}
    content = Wrappix::Templates::Main.render("test-api", "TestApi", config)

    # Verificar requires básicos
    assert_match(%r{require_relative "test-api/version"}, content)
    assert_match(%r{require_relative "test-api/configuration"}, content)
    assert_match(%r{require_relative "test-api/error"}, content)
    assert_match(%r{require_relative "test-api/request"}, content)
    assert_match(%r{require_relative "test-api/object"}, content)
    assert_match(%r{require_relative "test-api/collection"}, content)
    assert_match(%r{require_relative "test-api/cache"}, content)

    # Verificar estructura del módulo
    assert_match(/module TestApi/, content)
    assert_match(/class << self/, content)
    assert_match(/attr_accessor :configuration, :cache/, content)
    assert_match(/def configure/, content)
    assert_match(/yield\(configuration\) if block_given\?/, content)
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

    # Verificar requires de recursos con el nuevo formato (con subdirectorio resources/)
    assert_match(%r{require_relative "test-api/resources/users"}, content)
    assert_match(%r{require_relative "test-api/resources/posts"}, content)
    assert_match(%r{require_relative "test-api/resources/comments"}, content)
  end
end
