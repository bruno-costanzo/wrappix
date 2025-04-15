# test/wrappix/validation_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class ValidationTest < Minitest::Test
  def test_handles_missing_required_fields
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        File.write("minimal.yml", <<~YAML)
          base_url: "http://example.com"
        YAML

        result = nil
        capture_io do
          result = Wrappix.build("minimal.yml")
        end

        assert result, "Build debería usar valores por defecto"

        dir_name = File.basename(dir)
        normalized_name = dir_name.tr("-", "_")
        assert File.exist?("lib/#{normalized_name}.rb"), "No creó el archivo principal usando el nombre del directorio"
      end
    end
  end
end
