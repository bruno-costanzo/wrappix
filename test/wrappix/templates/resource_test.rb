require "test_helper"
require "wrappix/templates/resource"

class ResourceTemplateTest < Minitest::Test
  def test_renders_different_http_methods
    # Probar diferentes métodos HTTP
    resource_config = {
      "endpoints" => [
        {"name" => "list", "method" => "get", "path" => "items"},
        {"name" => "create", "method" => "post", "path" => "items"},
        {"name" => "update", "method" => "put", "path" => "items/{id}"},
        {"name" => "partial_update", "method" => "patch", "path" => "items/{id}"},
        {"name" => "remove", "method" => "delete", "path" => "items/{id}"}
      ]
    }

    content = Wrappix::Templates::Resource.render("TestApi", "items", resource_config)

    # Verificar que cada método HTTP está presente
    assert_match(/request\.get/, content)
    assert_match(/request\.post/, content)
    assert_match(/request\.put/, content)
    assert_match(/request\.patch/, content)
    assert_match(/request\.delete/, content)

    # Verificar que los métodos con parámetros en la ruta están correctos
    assert_match(/def update\(id/, content)
    assert_match(/def partial_update\(id/, content)
    assert_match(/def remove\(id/, content)

    # Verificar que los métodos sin parámetros en la ruta están correctos
    assert_match(/def list/, content)
    assert_match(/def create/, content)
  end

  def test_handles_params_parameter
    resource_config = {
      "endpoints" => [
        {"name" => "search", "method" => "get", "path" => "search", "params" => true},
        {"name" => "filter", "method" => "get", "path" => "filter/{type}", "params" => true}
      ]
    }

    content = Wrappix::Templates::Resource.render("TestApi", "search", resource_config)

    # Verificar que los métodos aceptan parámetros de query
    assert_match(/def search\(params = {}\)/, content)
    assert_match(/def filter\(type, params = {}\)/, content)
    assert_match(/params: params/, content)
  end

  def test_endpoints_return_objects_or_collections
    # Configuración para un endpoint que devuelve un objeto individual
    single_config = {
      "endpoints" => [
        {"name" => "get", "method" => "get", "path" => "items/{id}"}
      ]
    }

    single_content = Wrappix::Templates::Resource.render("TestApi", "items", single_config)

    # Verificar que devuelve un TestApi::Object
    assert_match(/response = request\.get/, single_content)
    assert_match(/TestApi::Object\.new\(response\)/, single_content)

    # Configuración para un endpoint que devuelve una colección
    collection_config = {
      "endpoints" => [
        {"name" => "list", "method" => "get", "path" => "items"}
      ]
    }

    collection_content = Wrappix::Templates::Resource.render("TestApi", "items", collection_config)

    # Verificar que devuelve un TestApi::Collection
    assert_match(/response = request\.get/, collection_content)
    assert_match(/TestApi::Collection\.from_response\(response, type: TestApi::Object\)/, collection_content)

    # Configuración con flag collection explícito
    explicit_config = {
      "endpoints" => [
        {"name" => "search", "method" => "get", "path" => "items/search", "collection": true}
      ]
    }

    explicit_content = Wrappix::Templates::Resource.render("TestApi", "items", explicit_config)

    # Verificar que respeta el flag collection
    assert_match(/TestApi::Collection\.from_response\(response, type: TestApi::Object\)/, explicit_content)
  end
end
