# frozen_string_literal: true

require_relative "wrappix/version"
require_relative "wrappix/builder"
require_relative "wrappix/configuration"

module Wrappix
  class Error < StandardError; end

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Configuration.new
      yield(configuration) if block_given?
      self
    end

    def build(config_file)
      Builder.new(config_file).build
    end
  end

  self.configuration = Configuration.new
end
