# frozen_string_literal: true

module Wrappix
  module Templates
    class Client
      def self.render(module_name, config)
        template = <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            class Client
              def initialize(configuration = #{module_name}.configuration)
                @configuration = configuration
              end

              #{resource_methods(module_name, config)}
            end
          end
        RUBY
        template.gsub(/^ +/, "")
      end

      def self.resource_methods(_module_name, config)
        resources = config["resources"] || {}

        resources.map do |name, _config|
          template = <<~RUBY.strip
            def #{name}
              @#{name} ||= Resources::#{name.capitalize}.new(self)
            end
          RUBY
          template.gsub(/^ +/, "")
        end.join("\n\n")
      end
    end
  end
end
