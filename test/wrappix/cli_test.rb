# frozen_string_literal: true

# test/wrappix/cli_test.rb
require "test_helper"
require "tmpdir"
require "yaml"
require "wrappix/cli"

class CliTest < Minitest::Test
  def test_build_command
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        # Crear archivo de configuración básico
        File.write("cli_config.yml", {
          "api_name" => "cli-api",
          "base_url" => "https://cli.example.com"
        }.to_yaml)

        # Capturar la salida estándar para verificar mensajes
        output = capture_io do
          Wrappix::CLI.start(["build", "cli_config.yml"])
        end

        # Verificar que se crearon los archivos (con nombres normalizados)
        assert File.exist?("lib/cli_api/configuration.rb"), "Missing configuration.rb"
        assert File.exist?("lib/cli_api/client.rb"), "Missing client.rb"
        assert File.exist?("lib/cli_api.rb"), "Missing main file"

        # Verificar que se mostró un mensaje de éxito
        assert_match(/generado correctamente/, output.join)
      end
    end
  end

  def test_build_command_with_nonexistent_file
    output = capture_io do
      # Se espera que falle, pero no queremos que el test falle

      Wrappix::CLI.start(["build", "nonexistent.yml"])
    rescue SystemExit
      # Thor normalmente sale con un código de error, capturamos eso
    end

    # Verificar que se mostró un mensaje de error
    assert_match(/Error: El archivo de configuración no existe/, output.join)
  end
end
