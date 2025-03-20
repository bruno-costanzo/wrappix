# frozen_string_literal: true

module Wrappix
  module Templates
    class Main
      def self.render(api_name, module_name, config)
        resources = config["resources"] || {}
        resource_requires = resources.keys.map do |r|
          singular = r.end_with?('s') ? r.chop : r
          "require_relative \"#{api_name}/#{singular}\"\nrequire_relative \"#{api_name}/#{singular}_resource\""
        end.join("\n")

        <<~RUBY
          # frozen_string_literal: true

          require_relative "#{api_name}/version"
          require_relative "#{api_name}/configuration"
          require_relative "#{api_name}/error"
          require_relative "#{api_name}/request"
          require_relative "#{api_name}/object"
          require_relative "#{api_name}/collection"
          require_relative "#{api_name}/cache"

          # Resources
          #{resource_requires}

          module #{module_name}
            class << self
              attr_accessor :configuration, :cache, :customer_id

              def configure
                self.configuration ||= Configuration.new
                yield(configuration) if block_given?
                self
              end
            end

            # Default to memory cache
            self.cache = MemoryCache.new
            self.configuration = Configuration.new
          end
        RUBY
      end
    end
  end
end
