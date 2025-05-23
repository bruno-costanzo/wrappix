# lib/wrappix/templates/collection.rb
# frozen_string_literal: true

module Wrappix
  module Templates
    class Collection
      def self.render(module_name, _config)
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            class Collection
              attr_reader :data, :next_href

              def self.from_response(response_body, type:)
                new(
                  data: response_body[:data]&.map { |attrs| type.new(attrs) },
                  next_href: response_body[:next_href]
                )
              end

              def initialize(data:, next_href:)
                @data = data
                @next_href = next_href
              end
            end
          end
        RUBY
      end
    end
  end
end
