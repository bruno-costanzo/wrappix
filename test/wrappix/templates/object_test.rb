# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/object"

class ObjectTemplateTest < Minitest::Test
  def test_generates_object_class
    content = Wrappix::Templates::Object.render("TestApi", {})

    assert_match(/require "ostruct"/, content)
    assert_match(/class Object < OpenStruct/, content)
    assert_match(/def initialize\(attributes\)/, content)
    assert_match(/super\(to_ostruct\(attributes\)\)/, content)
    assert_match(/def to_ostruct\(obj\)/, content)
    assert_match(/OpenStruct\.new\(obj\.transform_values/, content)
  end
end
