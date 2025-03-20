# frozen_string_literal: true

module Wrappix
  module Templates
    class Object
      def self.render(module_name, _config)
        <<~RUBY
          # frozen_string_literal: true

          require "ostruct"

          module #{module_name}
            class Object < OpenStruct
              def initialize(attributes)
                super(to_ostruct(attributes))
              end

              def to_ostruct(obj)
                if obj.is_a?(Hash)
                  OpenStruct.new(obj.transform_values { |val| to_ostruct(val) })
                elsif obj.is_a?(Array)
                  obj.map { |o| to_ostruct(o) }
                else
                  obj
                end
              end
            end
          end
        RUBY
      end
    end
  end
end
