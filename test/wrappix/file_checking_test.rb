# test/wrappix/file_checking_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FileCheckingTest < Minitest::Test
  def safe_build(config_file)
    unless File.exist?(config_file)
      puts "Error: El archivo no existe - #{config_file}"
      return false
    end

    Wrappix.build(config_file)
  end

  def test_detects_nonexistent_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        result = nil
        output = capture_io do
          result = safe_build("nonexistent.yml")
        end

        refute result, "Build debería fallar con un archivo inexistente"
        assert_match(/no existe/, output.join)
      end
    end
  end

  def test_accepts_existing_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("valid.yml", {
          "api_name" => "test-api",
          "base_url" => "https://example.com"
        }.to_yaml)

        result = nil
        capture_io do
          result = safe_build("valid.yml")
        end

        assert result, "Build debería funcionar con un archivo existente"
      end
    end
  end
end
