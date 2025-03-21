# frozen_string_literal: true

require_relative "../wrappix"
require "thor"

module Wrappix
  class CLI < Thor
    desc "build CONFIG_FILE", "Genera archivos del wrapper basados en CONFIG_FILE"
    def build(config_file)
      unless File.exist?(config_file)
        say "Error: El archivo de configuración no existe", :red
        exit(1)
      end

      if Wrappix.build(config_file)
        say "Wrapper generado correctamente", :green
        true
      else
        say "Error al generar el wrapper", :red
        false
      end
    end
  end
end
