# frozen_string_literal: true

module Wrappix
  module Templates
    class Resource
      def self.render(module_name, resource_name, resource_config)
        endpoints = resource_config["endpoints"] || []
        methods = endpoints.map do |endpoint|
          endpoint_method(module_name, resource_name, endpoint, resource_config)
        end.join("\n\n")

        class_name = resource_name.capitalize

        template = <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            module Resources
              class #{class_name}
                def initialize(client)
                  @client = client
                  @config = #{module_name}.configuration
                end

                #{methods}
              end
            end
          end
        RUBY
        # Remove leading whitespace from each line
        template.gsub(/^ +/, "")
      end

      def self.endpoint_method(module_name, _resource_name, endpoint, resource_config)
        name = endpoint["name"]
        method = endpoint["method"] || "get"
        path = endpoint["path"] || name

        response_format = resource_config["response_format"] || {}
        is_collection = endpoint["collection"] || %w[all list index search].include?(name)

        has_params = path.include?("{")
        param_list = has_params ? path.scan(/\{([^}]+)\}/).flatten : []

        endpoint_params = []
        endpoint_params.concat(param_list)
        endpoint_params << "params = {}" if endpoint["params"]
        endpoint_params << "body = {}" if %w[post put patch].include?(method)

        request_args = []
        request_args << "params: params" if endpoint["params"]
        request_args << "body: body" if %w[post put patch].include?(method)
        request_options = request_args.empty? ? "" : "(#{request_args.join(", ")})"

        path_with_params = path
        param_list.each do |param|
          path_with_params = path_with_params.gsub(/\{#{param}\}/, "\#{#{param}}")
        end

        response_transform = if is_collection
                               "#{module_name}::Collection.from_response(response, type: #{module_name}::Object)"
                             else
                               item_root = response_format["item_root"]
                               if item_root
                                 "#{module_name}::Object.new(response[:#{item_root}] || response[\"#{item_root}\"] || response)"
                               else
                                 "#{module_name}::Object.new(response)"
                               end
                             end

        template = <<~RUBY.strip
          def #{name}(#{endpoint_params.join(", ")})
            request = #{module_name}::Request.new("#{path_with_params}")
            response = request.#{method}#{request_options}

            #{response_transform}
          end
        RUBY
        template.gsub(/^ +/, "")
      end

      def self.generate_response_transform(module_name, is_collection, response_format)
        if is_collection
          collection_root = response_format["collection_root"] || "data"
          pagination_config = response_format["pagination"] || {}
          next_page_key = pagination_config["next_page_key"] || "next_href"

          template = <<~RUBY
            data = response[:#{collection_root}] || response["#{collection_root}"] || []
            next_href = response[:#{next_page_key}] || response["#{next_page_key}"]

            #{module_name}::Collection.from_response({
              data: data,
              next_href: next_href
            }, type: #{module_name}::Object)
          RUBY
          template.gsub(/^ +/, "")
        else
          item_root = response_format["item_root"]
          if item_root
            "#{module_name}::Object.new(response[:#{item_root}] || response[\"#{item_root}\"] || response)"
          else
            "#{module_name}::Object.new(response)"
          end
        end
      end
    end
  end
end
