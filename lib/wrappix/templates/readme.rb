# frozen_string_literal: true

module Wrappix
  module Templates
    class Readme
      def self.render(api_name, module_name, config)
        base_url = config["base_url"] || "https://api.example.com"
        auth_instructions = auth_setup_instructions(config)
        resource_docs = generate_resource_docs(module_name, config)

        <<~MARKDOWN
          # #{module_name} API Client

          A Ruby API wrapper for the #{api_name} API.

          ## Installation

          Add this line to your application's Gemfile:

          ```ruby
          gem '#{api_name}'
          ```

          And then execute:

          ```bash
          $ bundle install
          ```

          Or install it yourself as:

          ```bash
          $ gem install #{api_name}
          ```

          ## Configuration

          ```ruby
          #{module_name}.configure do |config|
            config.base_url = "#{base_url}"
            #{auth_instructions}
          end
          ```

          ## Usage

          ### Initializing the client

          ```ruby
          # Initialize the client
          client = #{module_name}.client
          ```

          ### Examples

          ```ruby
          #{usage_examples(module_name, config)}
          ```

          ### Working with responses

          Objects returned by the API can be accessed using dot notation:

          ```ruby
          user = client.users.get(123)
          puts user.id          # => 123
          puts user.name        # => "John Doe"
          puts user.email       # => "john@example.com"
          ```

          Collections include pagination support:

          ```ruby
          users = client.users.list

          # Iterate through items
          users.data.each do |user|
            puts user.name
          end

          # Check pagination info
          if users.next_href
            # More results available
          end
          ```

          ## Resources and Endpoints

          #{resource_docs}

          ## Error Handling

          ```ruby
          begin
            response = client.users.get(123)
          rescue #{module_name}::Error => e
            puts "Error: \#{e.message}"
            puts "Status: \#{e.status}"
            puts "Details: \#{e.body}"
          end
          ```

          ## API Documentation

          Detailed API documentation is available in the `docs/api.md` file, which includes:

          - All available endpoints
          - Required parameters
          - Example requests and responses
          - Authentication details

          ## Advanced Usage

          ### Caching

          #{module_name} uses a caching solution to improve efficiency (e.g., for caching tokens). By default, it uses a simple memory cache,
          but you can change the cache method by setting the `#{module_name}.cache` attribute.

          ```ruby
          # Use Redis cache
          #{module_name}.cache = Redis.new

          # Or use Rails cache
          #{module_name}.cache = Rails.cache

          # Or use file-based cache
          #{module_name}.cache = #{module_name}::FileCache.new

          # Or any object that responds to read/write/delete/clear
          #{module_name}.cache = YourCustomCache.new
          ```

          ### Custom Headers

          You can set custom headers for all requests:

          ```ruby
          #{module_name}.configure do |config|
            config.headers["User-Agent"] = "MyApp/1.0"
            config.headers["X-Custom-Header"] = "Value"
          end
          ```
        MARKDOWN
      end

      def self.auth_setup_instructions(config)
        case config["auth_type"]
        when "oauth"
          <<~RUBY.strip
            config.client_id = "your_client_id"
            config.client_secret = "your_client_secret"
            config.access_token = "your_access_token"
          RUBY
        when "basic"
          <<~RUBY.strip
            config.username = "your_username"
            config.password = "your_password"
          RUBY
        when "api_key"
          <<~RUBY.strip
            config.api_key = "your_api_key"
            config.api_key_header = "#{config["api_key_header"] || "X-Api-Key"}"
          RUBY
        else
          "# No authentication required"
        end
      end

      def self.usage_examples(_module_name, config)
        resources = config["resources"] || {}
        examples = []

        resources.each do |resource_name, resource_config|
          endpoints = resource_config["endpoints"] || []
          next if endpoints.empty?

          # Take the first endpoint as an example
          endpoint = endpoints.first
          method = endpoint["method"] || "get"
          has_params = endpoint["path"].to_s.include?("{")

          if has_params
            # Extract parameters
            params = endpoint["path"].scan(/\{([^}]+)\}/).flatten
            param_values = params.map { |_p| "123" } # Example values
            args = param_values.join(", ")

            examples << "# #{resource_name.capitalize} - #{endpoint["name"]} example"
            examples << "response = client.#{resource_name}.#{endpoint["name"]}(#{args})"
          else
            examples << "# #{resource_name.capitalize} - #{endpoint["name"]} example"
            examples << if %w[post put patch].include?(method)
                          "response = client.#{resource_name}.#{endpoint["name"]}({name: 'value', other_field: 'value'})"
                        else
                          "response = client.#{resource_name}.#{endpoint["name"]}"
                        end
          end

          examples << ""
        end

        examples.join("\n")
      end

      def self.generate_resource_docs(_module_name, config)
        resources = config["resources"] || {}
        docs = []

        resources.each do |resource_name, resource_config|
          docs << "### #{resource_name.capitalize}"
          endpoints = resource_config["endpoints"] || []

          endpoints.each do |endpoint|
            name = endpoint["name"]
            method = endpoint["method"] || "get"
            path = endpoint["path"] || name
            has_params = path.include?("{")

            docs << "#### `#{name}`"
            docs << "- HTTP Method: `#{method.upcase}`"
            docs << "- Path: `#{path}`"

            if has_params
              params = path.scan(/\{([^}]+)\}/).flatten
              docs << "- Path Parameters: #{params.map { |p| "`#{p}`" }.join(", ")}"
            end

            docs << "- Accepts additional query parameters" if endpoint["params"]

            # Usage example
            docs << "\n```ruby"
            if has_params
              params = path.scan(/\{([^}]+)\}/).flatten
              param_args = params.map { |p| "#{p}: 123" }.join(", ")

              docs << if endpoint["params"]
                        "client.#{resource_name}.#{name}(#{param_args}, {param1: 'value', param2: 'value'})"
                      else
                        "client.#{resource_name}.#{name}(#{param_args})"
                      end
            else
              docs << if %w[post put patch].include?(method)
                        "client.#{resource_name}.#{name}({field1: 'value', field2: 'value'})"
                      elsif endpoint["params"]
                        "client.#{resource_name}.#{name}({param1: 'value', param2: 'value'})"
                      else
                        "client.#{resource_name}.#{name}"
                      end
            end
            docs << "```\n"
          end
        end

        docs.join("\n")
      end
    end
  end
end
