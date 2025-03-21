# frozen_string_literal: true

require "test_helper"
require "wrappix/templates/documentation"

class DocumentationTemplateTest < Minitest::Test
  def test_generates_basic_documentation
    config = {
      "api_name" => "test-api",
      "base_url" => "https://api.example.com",
      "auth_type" => "oauth",
      "resources" => {
        "users" => {
          "endpoints" => [
            { "name" => "list", "method" => "get", "path" => "users" },
            { "name" => "get", "method" => "get", "path" => "users/{id}" },
            { "name" => "create", "method" => "post", "path" => "users" }
          ]
        },
        "posts" => {
          "endpoints" => [
            { "name" => "list", "method" => "get", "path" => "posts" }
          ]
        }
      }
    }

    content = Wrappix::Templates::Documentation.render("test-api", "TestApi", config)

    # Verificar contenido esencial en lugar de patrones específicos
    assert_includes content, "TestApi API Documentation"
    assert_includes content, "https://api.example.com"

    # Verificar sección de autenticación
    assert_includes content, "Authentication"
    assert_includes content, "OAuth 2.0 authentication"

    # Verificar listado de recursos
    assert_includes content, "Users"
    assert_includes content, "Posts"

    # Verificar documentación de endpoints
    assert_includes content, "list"
    assert_includes content, "get"
    assert_includes content, "create"
    assert_includes content, "/users"
    assert_includes content, "/users/{id}"

    # Verificar documentación de parámetros
    assert_includes content, "Parameters"
    assert_includes content, "id"

    # Verificar ejemplos de uso
    assert_includes content, "client.users.list"
    assert_includes content, "client.users.get"
    assert_includes content, "client.users.create"

    # Verificar ejemplos de respuesta
    assert_includes content, "Collection object"
    assert_includes content, "Returns a single Object"
    assert_includes content, "Returns the created object"
  end
end
