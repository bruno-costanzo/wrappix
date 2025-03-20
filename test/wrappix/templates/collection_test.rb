require "test_helper"
require "wrappix/templates/collection"

class CollectionTemplateTest < Minitest::Test
  def test_generates_collection_class
    content = Wrappix::Templates::Collection.render("TestApi", {})

    assert_match(/class Collection/, content)
    assert_match(/attr_reader :data, :next_href/, content)
    assert_match(/def self\.from_response\(response_body, type:\)/, content)
    assert_match(/data: response_body\[:data\]&\.map \{ \|attrs\| type\.new\(attrs\) \}/, content)
    assert_match(/next_href: response_body\[:next_href\]/, content)
  end
end
