# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "yaml"

class CompatibilityTest < Minitest::Test
  def test_creates_compatibility_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("compat_config.yml", {
          "api_name" => "compat-api",
          "base_url" => "https://api.example.com"
        }.to_yaml)

        Wrappix.build("compat_config.yml")

        assert File.exist?("lib/compat_api.rb"), "Archivo normalizado no creado"
        assert File.exist?("lib/compat-api.rb"), "Archivo de compatibilidad no creado"

        compat_content = File.read("lib/compat-api.rb")
        assert_match(/require_relative "compat_api"/, compat_content)
      end
    end
  end

  def test_both_formats_work_correctly
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("dual_config.yml", {
          "api_name" => "dual-api",
          "base_url" => "https://api.example.com"
        }.to_yaml)

        Wrappix.build("dual_config.yml")

        File.write("test_normalized.rb", <<~RUBY)
          $LOAD_PATH.unshift "#{dir}/lib"
          require "dual_api"
          puts "Loaded with normalized name: OK"
        RUBY

        File.write("test_original.rb", <<~RUBY)
          $LOAD_PATH.unshift "#{dir}/lib"
          require "dual-api"
          puts "Loaded with original name: OK"
        RUBY

        normalized_output = `ruby test_normalized.rb`
        original_output = `ruby test_original.rb`

        assert_match(/Loaded with normalized name: OK/, normalized_output)
        assert_match(/Loaded with original name: OK/, original_output)
      end
    end
  end
end
