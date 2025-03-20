# frozen_string_literal: true

module Wrappix
  module Templates
    class Cache
      def self.render(module_name, _config)
        <<~RUBY
          # frozen_string_literal: true

          module #{module_name}
            # Memory cache implementation
            class MemoryCache
              def initialize
                @store = {}
              end

              def read(key)
                @store[key]
              end

              def write(key, value)
                @store[key] = value
              end

              def delete(key)
                @store.delete(key)
              end

              def clear
                @store = {}
              end
            end

            # File cache implementation
            class FileCache
              def initialize(path = "#{module_name.downcase}_cache.yaml")
                require "yaml/store"
                @store = YAML::Store.new(path)
              end

              def read(key)
                @store.transaction(true) { @store[key] }
              end

              def write(key, value)
                @store.transaction { @store[key] = value }
              end

              def delete(key)
                @store.transaction { @store.delete(key) }
              end

              def clear
                @store.transaction { @store.roots.each { |key| @store.delete(key) } }
              end
            end
          end
        RUBY
      end
    end
  end
end
