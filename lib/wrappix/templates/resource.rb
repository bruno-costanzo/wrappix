module Wrappix
  module Templates
    class Resource
      def self.render(module_name, resource_name, resource_config)
        endpoints = resource_config["endpoints"] || []
        methods = endpoints.map { |endpoint| endpoint_method(module_name, endpoint) }.join("\n\n")

        # Para normalizar el nombre del recurso
        class_name = resource_name.capitalize

        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            module Resources
              class #{class_name}
                def initialize(client)
                  @client = client
                end

                #{methods}
              end
            end
          end
        RUBY
      end

      def self.endpoint_method(module_name, endpoint)
        name = endpoint["name"]
        method = endpoint["method"] || "get"
        path = endpoint["path"] || name

        # Determinar si es una colección
        is_collection = endpoint["collection"] || ["all", "list", "index", "search"].include?(name)

        # Procesar parámetros del path
        has_params = path.include?("{")
        param_list = has_params ? path.scan(/\{([^}]+)\}/).flatten : []

        # Preparar los parámetros del método
        endpoint_params = []
        endpoint_params.concat(param_list)
        endpoint_params << "params = {}" if endpoint["params"]
        endpoint_params << "body = {}" if ["post", "put", "patch"].include?(method)

        # Preparar argumentos para el método request
        request_args = []
        request_args << "params: params" if endpoint["params"]
        request_args << "body: body" if ["post", "put", "patch"].include?(method)
        request_options = request_args.empty? ? "" : "(#{request_args.join(", ")})"

        # Generar path con reemplazos de variables
        path_with_params = path
        param_list.each do |param|
          path_with_params = path_with_params.gsub(/\{#{param}\}/, "\#{#{param}}")
        end

        # Código para transformar la respuesta
        response_transform = if is_collection
          "#{module_name}::Collection.from_response(response, type: #{module_name}::Object)"
        else
          "#{module_name}::Object.new(response)"
        end

        <<~RUBY.strip
          def #{name}(#{endpoint_params.join(", ")})
            request = #{module_name}::Request.new("#{path_with_params}")
            response = request.#{method}#{request_options}

            #{response_transform}
          end
        RUBY
      end
    end
  end
end
