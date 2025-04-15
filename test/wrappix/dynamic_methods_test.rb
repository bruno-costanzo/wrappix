# test/wrappix/dynamic_methods_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"

class DynamicMethodsTest < Minitest::Test
  def test_generates_dynamic_resource_methods
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("dynamic_config.yml", {
          "api_name" => "dynamic-api",
          "base_url" => "https://api.example.com",
          "resources" => {
            "users" => {
              "endpoints" => [
                { "name" => "list", "path" => "users" }
              ]
            },
            "products" => {
              "endpoints" => [
                { "name" => "list", "path" => "products" }
              ]
            },
            "orders" => {
              "endpoints" => [
                { "name" => "list", "path" => "orders" }
              ]
            }
          }
        }.to_yaml)

        Wrappix.build("dynamic_config.yml")

        $LOAD_PATH.unshift "#{dir}/lib"
        require "dynamic_api"

        DynamicApi.configure do |config|
          config.base_url = "https://api.example.com"
        end

        client = DynamicApi.client

        assert_respond_to client, :users
        assert_respond_to client, :products
        assert_respond_to client, :orders

        assert_instance_of DynamicApi::Resources::Users, client.users
        assert_instance_of DynamicApi::Resources::Products, client.products
        assert_instance_of DynamicApi::Resources::Orders, client.orders

        assert_respond_to client.users, :list
        assert_respond_to client.products, :list
        assert_respond_to client.orders, :list
      end
    end
  end
end
