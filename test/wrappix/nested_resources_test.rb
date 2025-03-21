# test/wrappix/nested_resources_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"

class NestedResourcesTest < Minitest::Test
  def test_handles_nested_resources
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Configuración con recursos anidados (usando IDs en paths)
        File.write("nested_config.yml", {
          "api_name" => "nested-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "get", "path" => "users/{id}" }
              ]
            },
            "posts" => {
              "endpoints" => [
                { "name" => "list_for_user", "path" => "users/{user_id}/posts" },
                { "name" => "get", "path" => "posts/{id}" }
              ]
            },
            "comments" => {
              "endpoints" => [
                { "name" => "list_for_post", "path" => "posts/{post_id}/comments" },
                { "name" => "get", "path" => "comments/{id}" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("nested_config.yml")

        # Verificar que se crearon los recursos correctamente
        assert File.exist?("lib/nested_api/resources/users.rb")
        assert File.exist?("lib/nested_api/resources/posts.rb")
        assert File.exist?("lib/nested_api/resources/comments.rb")

        # Verificar el contenido de los recursos
        posts_content = File.read("lib/nested_api/resources/posts.rb")
        assert_match(/def list_for_user\(user_id\)/, posts_content)
        assert_match(%r{request = NestedApi::Request.new\("users/\#{user_id}/posts"\)}, posts_content)

        comments_content = File.read("lib/nested_api/resources/comments.rb")
        assert_match(/def list_for_post\(post_id\)/, comments_content)
        assert_match(%r{request = NestedApi::Request.new\("posts/\#{post_id}/comments"\)}, comments_content)
      end
    end
  end
end
