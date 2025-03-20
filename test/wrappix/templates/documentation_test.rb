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
            {"name" => "list", "method" => "get", "path" => "users"},
            {"name" => "get", "method" => "get", "path" => "users/{id}"},
            {"name" => "create", "method" => "post", "path" => "users"}
          ]
        },
        "posts" => {
          "endpoints" => [
            {"name" => "list", "method" => "get", "path" => "posts"}
          ]
        }
      }
    }

    content = Wrappix::Templates::Documentation.render("test-api", "TestApi", config)

    # Verificar contenido de la documentación
    assert_match(/# TestApi API Documentation/, content)
    assert_match(/API Base URL: `https:\/\/api\.example\.com`/, content)

    # Verificar sección de autenticación
    assert_match(/This API uses OAuth 2.0 authentication/, content)

    # Verificar listado de recursos
    assert_match(/- \[Users\]/, content)
    assert_match(/- \[Posts\]/, content)

    # Verificar documentación de endpoints
    assert_match(/### list/, content)
    assert_match(/### get/, content)
    assert_match(/### create/, content)
    assert_match(/\*\*GET\*\* `https:\/\/api\.example\.com\/users`/, content)
    assert_match(/\*\*GET\*\* `https:\/\/api\.example\.com\/users\/{id}`/, content)
    assert_match(/\*\*POST\*\* `https:\/\/api\.example\.com\/users`/, content)

    # Verificar documentación de parámetros
    assert_match(/Path Parameters/, content)
    assert_match(/`id`: Required/, content)

    # Verificar ejemplos de uso
    assert_match(/client\.users\.list/, content)
    assert_match(/client\.users\.get\(id\)/, content)
    assert_match(/client\.users\.create\(body\)/, content)

    # Verificar ejemplos de respuesta
    assert_match(/# Returns a Collection object/, content)
    assert_match(/# Returns a single Object/, content)
    assert_match(/# Returns the created object/, content)
  end
end
