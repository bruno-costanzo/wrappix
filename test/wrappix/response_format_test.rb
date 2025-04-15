# test/wrappix/response_format_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"

class ResponseFormatTest < Minitest::Test
  def test_handles_custom_response_format
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("format_config.yml", {
          "api_name" => "format-api",
          "base_url" => "https://api.example.com",
          "response_format" => {
            "collection_root" => "results",
            "item_root" => "item",
            "pagination" => {
              "next_page_key" => "next_page",
              "total_count_key" => "count",
              "limit_key" => "per_page"
            }
          },
          "resources" => {
            "products" => {
              "endpoints" => [
                { "name" => "list", "path" => "products" },
                { "name" => "get", "path" => "products/{id}" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("format_config.yml")

        assert File.exist?("lib/format_api/resources/products.rb")

        products_content = File.read("lib/format_api/resources/products.rb")

        assert_match(/FormatApi::Collection\.from_response\(response, type: FormatApi::Object\)/, products_content)

        assert_match(/FormatApi::Object\.new\(response/, products_content)
      end
    end
  end

  def test_resource_specific_response_format
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("specific_config.yml", {
          "api_name" => "specific-api",
          "base_url" => "https://api.example.com",
          "response_format" => {
            "collection_root" => "data"
          },
          "resources" => {
            "users" => {
              "response_format" => {
                "collection_root" => "users",
                "item_root" => "user"
              },
              "endpoints" => [
                { "name" => "list", "path" => "users" },
                { "name" => "get", "path" => "users/{id}" }
              ]
            },
            "products" => {
              "response_format" => {
                "collection_root" => "products",
                "item_root" => "product"
              },
              "endpoints" => [
                { "name" => "list", "path" => "products" },
                { "name" => "get", "path" => "products/{id}" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("specific_config.yml")

        assert File.exist?("lib/specific_api/resources/users.rb")
        assert File.exist?("lib/specific_api/resources/products.rb")

        users_content = File.read("lib/specific_api/resources/users.rb")
        products_content = File.read("lib/specific_api/resources/products.rb")

        assert_match(/SpecificApi::Collection\.from_response\(response, type: SpecificApi::Object\)/, users_content)
        assert_match(/SpecificApi::Collection\.from_response\(response, type: SpecificApi::Object\)/, products_content)
      end
    end
  end
end
