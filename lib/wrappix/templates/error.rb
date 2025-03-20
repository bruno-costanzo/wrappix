# frozen_string_literal: true

module Wrappix
  module Templates
    class Error
      def self.render(module_name, _config)
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            class Error < StandardError
              attr_reader :body, :status

              def initialize(message, body = nil, status = nil)
                @body = body
                @status = status
                super(message)
              end
            end
          end
        RUBY
      end
    end
  end
end
