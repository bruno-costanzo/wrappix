# test/wrappix/documentation_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"

class DocumentationTest < Minitest::Test
  def test_creates_documentation_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("doc_config.yml", {
          "api_name" => "doc-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "list", "path" => "users" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("doc_config.yml")

        assert File.exist?("docs/api.md"), "Archivo de documentación API no creado"

        doc_content = File.read("docs/api.md")
        assert_match(/# DocApi API Documentation/, doc_content)
        assert_match(/## Resources/, doc_content)
        assert_match(/## Authentication/, doc_content)
      end
    end
  end
end
