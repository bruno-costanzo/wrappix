# frozen_string_literal: true

module Wrappix
  class Configuration
    attr_accessor :base_url, :headers, :timeout
    attr_reader :resources

    def initialize
      @base_url = nil
      @headers = {}
      @timeout = 30
      @resources = {}
    end

    def add_resource(name, options = {})
      @resources[name.to_sym] = options
    end

    def resources=(resource_hash)
      resource_hash.each do |name, options|
        add_resource(name, options)
      end
    end
  end
end
