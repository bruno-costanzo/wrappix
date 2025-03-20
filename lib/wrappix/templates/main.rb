# frozen_string_literal: true

module Wrappix
  module Templates
    class Main
      def self.render(api_name, module_name, config)
        resources = config["resources"] || {}
        resource_requires = resources.keys.map { |r| "require_relative \"#{api_name}/resources/#{r}\"" }.join("\n")

        <<~RUBY
          # frozen_string_literal: true

          require_relative "#{api_name}/version"
          require_relative "#{api_name}/configuration"
          require_relative "#{api_name}/error"
          require_relative "#{api_name}/request"
          require_relative "#{api_name}/client"

          # Recursos
          #{resource_requires}

          module #{module_name}
            class << self
              attr_accessor :configuration

              def configure
                self.configuration ||= Configuration.new
                yield(configuration) if block_given?
                self
              end

              def client
                @client ||= Client.new(configuration)
              end
            end

            self.configuration = Configuration.new
          end
        RUBY
      end
    end
  end
end
