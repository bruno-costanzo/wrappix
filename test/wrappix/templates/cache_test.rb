# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/cache"

class CacheTemplateTest < Minitest::Test
  def test_renders_cache_classes
    content = Wrappix::Templates::Cache.render("TestApi", {})

    # Verificar clase MemoryCache
    assert_match(/class MemoryCache/, content)
    assert_match(/def read\(key\)/, content)
    assert_match(/def write\(key, value\)/, content)
    assert_match(/def delete\(key\)/, content)
    assert_match(/def clear/, content)

    # Verificar clase FileCache
    assert_match(/class FileCache/, content)
    assert_match(%r{require "yaml/store"}, content)
    assert_match(/@store = YAML::Store\.new\(path\)/, content)
  end
end
