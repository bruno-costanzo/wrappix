# frozen_string_literal: true

module Wrappix
  module Templates
    class Tests
      def self.render(_api_name, module_name, config)
        resources = config["resources"] || {}

        test_content = <<~RUBY
          # frozen_string_literal: true

          require "test_helper"

          class #{module_name}Test < Minitest::Test
            def setup
              # Reset configuration before each test
              #{module_name}.configuration = #{module_name}::Configuration.new

              # Configure base settings
              #{module_name}.configure do |config|
                config.base_url = "#{config["base_url"] || "https://api.example.com"}"
              end
            end

            def teardown
              # No need to restore anything
            end

            #{config_tests(module_name, config)}

            #{client_tests(module_name, resources.keys)}

            #{error_tests(module_name)}
          end
        RUBY

        # Generar tests de recursos en archivos separados
        resources.each do |resource_name, resource_config|
          resource_test(module_name, resource_name, resource_config, config)
          # Aquí podrías devolver o guardar estos tests en archivos separados
        end

        test_content
      end

      def self.config_tests(module_name, config)
        auth_config = case config["auth_type"]
                      when "oauth"
                        <<~RUBY.strip
                          config.client_id = "test_client_id"
                          config.client_secret = "test_client_secret"
                          config.token_url = "#{config["token_url"] || "https://api.example.com/oauth/token"}"
                        RUBY
                      when "basic"
                        <<~RUBY.strip
                          config.username = "test_username"
                          config.password = "test_password"
                        RUBY
                      when "api_key"
                        <<~RUBY.strip
                          config.api_key = "test_api_key"
                          config.api_key_header = "#{config["api_key_header"] || "X-Api-Key"}"
                        RUBY
                      else
                        ""
                      end

        <<~RUBY
          def test_configuration
            #{module_name}.configure do |config|
              config.base_url = "https://api.test.org"
              config.timeout = 60
              #{auth_config}
            end

            assert_equal "https://api.test.org", #{module_name}.configuration.base_url
            assert_equal 60, #{module_name}.configuration.timeout
            #{verify_auth_config(module_name, config)}
          end
        RUBY
      end

      def self.verify_auth_config(module_name, config)
        case config["auth_type"]
        when "oauth"
          <<~RUBY
            assert_equal "test_client_id", #{module_name}.configuration.client_id
            assert_equal "test_client_secret", #{module_name}.configuration.client_secret
          RUBY
        when "basic"
          <<~RUBY
            assert_equal "test_username", #{module_name}.configuration.username
            assert_equal "test_password", #{module_name}.configuration.password
          RUBY
        when "api_key"
          <<~RUBY
            assert_equal "test_api_key", #{module_name}.configuration.api_key
          RUBY
        else
          ""
        end
      end

      def self.client_tests(module_name, resource_names)
        resource_assertions = resource_names.map do |name|
          "    assert_respond_to client, :#{name}"
        end.join("\n")

        <<~RUBY
          def test_client_initialization
            client = #{module_name}::Client.new

            assert_instance_of #{module_name}::Client, client
          #{resource_assertions}
          end
        RUBY
      end

      def self.resource_test(module_name, resource_name, resource_config, global_config)
        endpoints = resource_config["endpoints"] || []

        endpoint_tests = endpoints.map do |endpoint|
          endpoint_test(module_name, resource_name, endpoint, resource_config, global_config)
        end.join("\n\n")

        <<~RUBY
          # Tests for #{resource_name} resource
          #{endpoint_tests}
        RUBY
      end

      def self.endpoint_test(module_name, resource_name, endpoint, resource_config, global_config)
        name = endpoint["name"]
        method = endpoint["method"] || "get"
        path = endpoint["path"] || name

        # Obtener los casos de prueba definidos o crear uno predeterminado
        test_cases = endpoint["tests"] || [create_default_test_case(endpoint)]

        # Generar un test para cada caso
        test_cases.map.with_index do |test_case, index|
          generate_test_method(module_name, resource_name, name, method, path, test_case, index, resource_config,
                               global_config)
        end.join("\n\n")
      end

      def self.create_default_test_case(endpoint)
        name = endpoint["name"]
        path = endpoint["path"] || name
        is_collection = endpoint["collection"] || %w[all list index search].include?(name)

        # Obtener los parámetros del path
        path_params = path.scan(/\{([^}]+)\}/).flatten
        path_params_values = path_params.map { |p| [p, "123"] }.to_h

        # Crear un caso de prueba predeterminado
        {
          "description" => "funciona correctamente",
          "request" => {
            "path_params" => path_params_values,
            "params" => endpoint["params"] ? { "page" => 1 } : {},
            "body" => %w[post put patch].include?(endpoint["method"].to_s) ? { "name" => "Test" } : {}
          },
          "response" => {
            "status" => 200,
            "body" => if is_collection
                        { "data" => [{ "id" => 1, "name" => "Test" }], "next_href" => "/next" }
                      else
                        { "id" => 1, "name" => "Test" }
                      end
          }
        }
      end

      def self.generate_test_method(module_name, resource_name, endpoint_name, method, path, test_case, index, resource_config, global_config)
        description = test_case["description"] || "case #{index + 1}"
        # Normalizar la descripción para el nombre del método
        method_name_desc = description.downcase.gsub(/[^a-z0-9]/, "_")

        request = test_case["request"] || {}
        response = test_case["response"] || {}

        # Preparar los parámetros del path
        path_params = request["path_params"] || {}
        path_params.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")

        # Preparar los parámetros de la consulta y el cuerpo
        query_params = request["params"] || {}
        body = request["body"] || {}

        # Construir la URL con los parámetros del path reemplazados
        test_url = path.dup
        path_params.each do |key, value|
          test_url.gsub!(/\{#{key}\}/, value.to_s)
        end

        # Si la URL comienza con http:// o https://, extraer solo el path
        if test_url.start_with?("http://", "https://")
          # Eliminar el protocolo y el dominio para quedarnos solo con el path
          test_url = test_url.sub(%r{^https?://[^/]+}, "")
          test_url = test_url[1..] if test_url.start_with?("/") # Quitar el slash inicial
        end

        # Construir los argumentos de la llamada
        call_args = []
        call_args.concat(path_params.values.map(&:inspect))
        call_args << query_params.inspect if query_params.any?
        call_args << body.inspect if body.any?

        # Generar el código para verificar la respuesta
        response_format = resource_config["response_format"] || global_config["response_format"] || {}
        response_assertions = generate_response_assertions(module_name, endpoint_name, response, response_format)

        <<~RUBY
          def test_#{resource_name}_#{endpoint_name}_#{method_name_desc}
            # Stub the HTTP request
            status = #{response["status"] || 200}
            response_body = #{response["body"].inspect}

            @stubs.#{method}("#{test_url}") do |env|
              # Verificar que los parámetros de consulta coincidan
              if env.body.is_a?(String) && !env.body.empty?
                request_body = JSON.parse(env.body)
                # Aquí podrías agregar verificaciones de body si es necesario
              end

              [status, {'Content-Type' => 'application/json'}, response_body.is_a?(String) ? response_body : response_body.to_json]
            end

            client = #{module_name}::Client.new

            #{handle_error_case(response)}
            result = client.#{resource_name}.#{endpoint_name}(#{call_args.join(", ")})

            #{response_assertions}
          end
        RUBY
      end

      def self.verify_request_env(query_params, body, method)
        checks = []

        if query_params.any?
          params_checks = query_params.map do |key, value|
            "assert_equal #{value.inspect}, Rack::Utils.parse_nested_query(env.url.query)[#{key.to_s.inspect}]"
          end
          checks.concat(params_checks)
        end

        if %w[post put patch].include?(method.to_s) && body.any?
          checks << "request_body = JSON.parse(env.body)"

          body_checks = body.map do |key, value|
            "assert_equal #{value.inspect}, request_body[#{key.to_s.inspect}]"
          end
          checks.concat(body_checks)
        end

        checks.join("\n              ")
      end

      def self.handle_error_case(response)
        status = response["status"] || 200

        if status >= 400
          <<~RUBY
            assert_raises(#{module_name}::Error) do
          RUBY
        else
          ""
        end
      end

      def self.generate_response_assertions(module_name, endpoint_name, response, response_format)
        status = response["status"] || 200

        if status >= 400
          "  end  # assert_raises"
        else
          body = response["body"] || {}

          # Verificar si el cuerpo es un hash antes de intentar usar key?
          if body.is_a?(String)
            # Si el cuerpo es una cadena (como en el caso de las imágenes binarias)
            <<~RUBY
              assert_instance_of #{module_name}::Object, result
              # El resultado es probablemente una URL o datos binarios
            RUBY
          else
            is_collection = %w[all list index search query].include?(endpoint_name) ||
                            (body.is_a?(Hash) && (body.key?("data") || body.key?(:data) ||
                             (response_format["collection_root"] &&
                              (body.key?(response_format["collection_root"]) ||
                               body.key?(response_format["collection_root"].to_sym)))))

            if is_collection
              collection_root = response_format["collection_root"] || "data"
              items = body[collection_root] || body[collection_root.to_sym] || []

              if items.empty?
                <<~RUBY
                  assert_instance_of #{module_name}::Collection, result
                  assert_empty result.data
                RUBY
              else
                <<~RUBY
                  assert_instance_of #{module_name}::Collection, result
                  assert_equal #{items.size}, result.data.size

                  # Verify first item properties
                  if result.data.any?
                    first_item = result.data.first
                    #{generate_item_assertions(items.first)}
                  end
                RUBY
              end
            else
              item_root = response_format["item_root"]
              item = item_root ? (body[item_root] || body[item_root.to_sym] || {}) : body

              <<~RUBY
                assert_instance_of #{module_name}::Object, result
                #{generate_item_assertions(item)}
              RUBY
            end
          end
        end
      end

      def self.generate_item_assertions(item)
        return "# No item data to assert" if !item || !item.is_a?(Hash) || item.empty?

        item.map do |key, value|
          if value.is_a?(Hash) || value.is_a?(Array)
            "assert_not_nil result.#{key}"
          else
            "assert_equal #{value.inspect}, result.#{key}"
          end
        end.join("\n      ")
      end

      def self.error_tests(module_name)
        <<~RUBY
          def test_error_handling
            error = #{module_name}::Error.new("Test error", {error: "details"}, 400)

            assert_equal "Test error", error.message
            assert_equal({error: "details"}, error.body)
            assert_equal 400, error.status
          end

          def test_http_error_response
            @stubs.get("error_test") do
              [404, {'Content-Type' => 'application/json'}, {error: "Resource not found"}.to_json]
            end

            error = assert_raises(#{module_name}::Error) do
              #{module_name}::Request.new("error_test").get
            end

            assert_equal 404, error.status
            assert_includes error.message, "Resource not found"
          end
        RUBY
      end
    end
  end
end
