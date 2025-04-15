# frozen_string_literal: true

module Wrappix
  module Templates
    class Documentation
      def self.render(_api_name, module_name, config)
        base_url = config["base_url"] || "https://api.example.com"
        resources = config["resources"] || {}

        # Cabecera y descripción general
        doc = <<~MARKDOWN
          # #{module_name} API Documentation

          This document provides detailed information about the endpoints available in the #{module_name} API client.

          **API Base URL:** `#{base_url}`

          ## Table of Contents

          - [Authentication](#authentication)
          #{resources.keys.map { |r| "- [#{r.capitalize}](##{r})" }.join("\n  ")}

          ## Authentication

          #{render_authentication_docs(config)}

          ## Resources

        MARKDOWN

        # Añadir documentación para cada recurso
        resources.each do |resource_name, resource_config|
          doc += render_resource_docs(resource_name, resource_config, module_name, base_url)
        end

        doc
      end

      def self.render_authentication_docs(config)
        case config["auth_type"]
        when "oauth"
          <<~MARKDOWN
            This API uses OAuth 2.0 authentication. You need to obtain an access token from the authorization server.

            ```ruby
            #{config["api_name"].gsub("-", "_").capitalize}.configure do |config|
              config.client_id = "YOUR_CLIENT_ID"
              config.client_secret = "YOUR_CLIENT_SECRET"
            end
            ```
          MARKDOWN
        when "basic"
          <<~MARKDOWN
            This API uses HTTP Basic Authentication.

            ```ruby
            #{config["api_name"].gsub("-", "_").capitalize}.configure do |config|
              config.username = "YOUR_USERNAME"
              config.password = "YOUR_PASSWORD"
            end
            ```
          MARKDOWN
        when "api_key"
          header = config["api_key_header"] || "X-Api-Key"
          <<~MARKDOWN
            This API uses API Key authentication. The key should be provided in the `#{header}` header.

            ```ruby
            #{config["api_name"].gsub("-", "_").capitalize}.configure do |config|
              config.api_key = "YOUR_API_KEY"
            end
            ```
          MARKDOWN
        else
          "This API does not require authentication."
        end
      end

      def self.render_resource_docs(resource_name, resource_config, module_name, base_url)
        endpoints = resource_config["endpoints"] || []
        singular_name = resource_name.end_with?("s") ? resource_name.chop : resource_name

        doc = <<~MARKDOWN

          <a name="#{resource_name}"></a>
          ## #{resource_name.capitalize}

        MARKDOWN

        endpoints.each do |endpoint|
          doc += render_endpoint_docs(endpoint, resource_name, singular_name, module_name, base_url)
        end

        doc
      end

      def self.render_endpoint_docs(endpoint, resource_name, singular_name, _module_name, base_url)
        name = endpoint["name"]
        method = endpoint["method"]&.upcase || "GET"
        path = endpoint["path"] || name

        path_params = path.scan(/\{([^}]+)\}/).flatten

        full_url = "#{base_url.chomp("/")}/#{path}"

        method_params = []
        method_params.concat(path_params)
        method_params << "params" if endpoint["params"]
        method_params << "body" if %w[POST PUT PATCH].include?(method)

        client_call = "client.#{resource_name}.#{name}(#{method_params.join(", ")})"

        doc = <<~MARKDOWN

          ### #{name}

          **#{method}** `#{full_url}`

          #{endpoint["description"] || "No description provided."}

          #### Parameters
        MARKDOWN

        # Añadir documentación de parámetros
        if path_params.empty? && !endpoint["params"] && !%w[POST PUT PATCH].include?(method)
          doc += "\nThis endpoint does not require any parameters.\n"
        else
          if path_params.any?
            doc += "\n**Path Parameters:**\n\n"
            path_params.each do |param|
              doc += "- `#{param}`: Required. #{param_description(param)}\n"
            end
          end

          if endpoint["params"]
            doc += "\n**Query Parameters:**\n\n"
            doc += "- This endpoint accepts additional query parameters.\n"
          end

          if %w[POST PUT PATCH].include?(method)
            doc += "\n**Request Body:**\n\n"
            doc += "- This endpoint accepts a request body with the resource attributes.\n"
          end
        end

        # Añadir ejemplos de uso
        doc += <<~MARKDOWN

          #### Example Usage

          ```ruby
          #{client_call}
          ```

          #### Response

          #{response_example(name, singular_name, endpoint["collection"])}
        MARKDOWN

        doc
      end

      def self.param_description(param)
        case param
        when "id"
          "The unique identifier of the resource."
        when "customer_id"
          "The identifier of the customer."
        when /^(\w+)_id$/
          "The identifier of the #{::Regexp.last_match(1)}."
        else
          "Description not available."
        end
      end

      def self.response_example(name, resource_name, _is_collection)
        case name
        when "list", "all", "index", "search"
          <<~MARKDOWN
            ```ruby
            # Returns a Collection object
            collection.data.each do |#{resource_name}|
              puts #{resource_name}.id
              puts #{resource_name}.name
              # Other attributes...
            end

            # Pagination information
            puts collection.next_href  # URL for the next page, if available
            ```
          MARKDOWN
        when "get", "find", "show"
          <<~MARKDOWN
            ```ruby
            # Returns a single Object
            puts #{resource_name}.id
            puts #{resource_name}.name
            # Other attributes...
            ```
          MARKDOWN
        when "create"
          <<~MARKDOWN
            ```ruby
            # Returns the created object
            puts #{resource_name}.id
            puts #{resource_name}.created_at
            # Other attributes...
            ```
          MARKDOWN
        when "update"
          <<~MARKDOWN
            ```ruby
            # Returns the updated object
            puts #{resource_name}.id
            puts #{resource_name}.updated_at
            # Other attributes...
            ```
          MARKDOWN
        when "delete", "destroy", "remove"
          <<~MARKDOWN
            ```ruby
            # Returns a success indicator or the deleted object
            puts "Resource deleted successfully"
            ```
          MARKDOWN
        else
          <<~MARKDOWN
            ```ruby
            # Returns a response specific to this endpoint
            puts response  # Examine the response structure
            ```
          MARKDOWN
        end
      end
    end
  end
end
