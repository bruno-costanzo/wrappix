# frozen_string_literal: true

module Wrappix
  module Templates
    class Resource
      def self.render(module_name, resource_name, resource_config)
        endpoints = resource_config["endpoints"] || []
        methods = endpoints.map { |endpoint| endpoint_method(module_name, endpoint) }.join("\n\n")

        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            module Resources
              class #{resource_name.capitalize}
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
        params = endpoint["params"] ? ", params: params" : ""

        # Determinar si es una colección o un objeto individual
        # Por convención, consideramos que métodos como "list", "search" devuelven colecciones
        is_collection = endpoint["collection"] || ["list", "search", "index"].include?(name)

        # Reemplazar placeholders en la ruta, como {id}
        has_params = path.include?("{")

        if has_params
          # Para rutas como "users/{id}"
          param_list = path.scan(/\{([^}]+)\}/).flatten
          method_params = param_list.join(", ")
          method_params += ", params = {}" if endpoint["params"]

          path_with_params = path.gsub(/\{([^}]+)\}/) { |m| "\#{#{$1}}" }

          <<~RUBY.strip
            def #{name}(#{method_params})
              request = #{module_name}::Request.new("#{path_with_params}")
              response = request.#{method}(#{params})

              #{wrap_response_code(module_name, is_collection)}
            end
          RUBY
        else
          # Para rutas simples
          method_params = endpoint["params"] ? "params = {}" : ""

          <<~RUBY.strip
            def #{name}(#{method_params})
              request = #{module_name}::Request.new("#{path}")
              response = request.#{method}(#{params})

              #{wrap_response_code(module_name, is_collection)}
            end
          RUBY
        end
      end

      def self.wrap_response_code(module_name, is_collection)
        if is_collection
          "#{module_name}::Collection.from_response(response, type: #{module_name}::Object)"
        else
          "#{module_name}::Object.new(response)"
        end
      end
    end
  end
end
