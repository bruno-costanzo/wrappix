# frozen_string_literal: true

require "yaml"
require "fileutils"
require_relative "templates/configuration"
require_relative "templates/client"
require_relative "templates/request"
require_relative "templates/error"
require_relative "templates/resource"
require_relative "templates/main"
require_relative "templates/readme"

module Wrappix
  class Builder
    def initialize(config_file)
      @config = YAML.load_file(config_file)
      @api_name = @config["api_name"] || File.basename(Dir.pwd)
      @module_name = @api_name.split('-').map(&:capitalize).join
    end

    def build
      create_base_files
      create_resource_files
      create_readme
    end

    private

    def create_base_files
      create_file("lib/#{@api_name}/configuration.rb", Templates::Configuration.render(@module_name, @config))
      create_file("lib/#{@api_name}/client.rb", Templates::Client.render(@module_name, @config))
      create_file("lib/#{@api_name}/request.rb", Templates::Request.render(@module_name, @config))
      create_file("lib/#{@api_name}/error.rb", Templates::Error.render(@module_name, @config))
      update_main_file
    end

    def create_resource_files
      FileUtils.mkdir_p("lib/#{@api_name}/resources")

      resources = @config["resources"] || {}
      resources.each do |resource_name, resource_config|
        create_file(
          "lib/#{@api_name}/resources/#{resource_name}.rb",
          Templates::Resource.render(@module_name, resource_name, resource_config)
        )
      end
    end

    def update_main_file
      main_file = "lib/#{@api_name}.rb"
      create_file(main_file, Templates::Main.render(@api_name, @module_name, @config))
    end

    def create_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))

      File.open(path, "w") do |file|
        file.write(content)
      end
      puts "File created: #{path}"
    end

    def create_readme
      create_file("README.md", Templates::Readme.render(@api_name, @module_name, @config))
    end
  end
end
