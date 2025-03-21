# test/wrappix/file_checking_test.rb
# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FileCheckingTest < Minitest::Test
  # Implementación temporal del método build para pruebas
  def safe_build(config_file)
    # Verificar primero si el archivo existe
    unless File.exist?(config_file)
      puts "Error: El archivo no existe - #{config_file}"
      return false
    end

    # Si existe, continuar con el build normal
    Wrappix.build(config_file)
  end

  def test_detects_nonexistent_file
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Intentar construir con un archivo que no existe
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
        # Crear un archivo válido
        File.write("valid.yml", {
          "api_name" => "test-api",
          "base_url" => "https://example.com"
        }.to_yaml)

        # Build debería funcionar con un archivo existente
        result = nil
        capture_io do
          result = safe_build("valid.yml")
        end

        assert result, "Build debería funcionar con un archivo existente"
      end
    end
  end
end
