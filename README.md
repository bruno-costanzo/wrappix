# Wrappix

Wrappix is a code generator that creates Ruby API client libraries from a YAML configuration file. It helps you build structured wrappers for REST APIs with minimal effort.

## Features

- **Complete code generation**: creates all classes and methods needed to interact with a REST API
- **Configurable**: define resources, endpoints, and parameters in a simple YAML file
- **Multiple authentication types**: supports OAuth, Basic authentication, and API keys
- **Automatic documentation**: generates README with usage examples and instructions
- **Error handling**: integrated HTTP error management
- **Elegant interface**: fluent API inspired by Ruby best practices

## Installation

Add this line to your Gemfile:

```ruby
gem 'wrappix'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install wrappix

## Usage

Wrappix can be used in two primary ways:
1. To generate a standalone API wrapper gem
2. To create an API client within an existing project

### 1. Create a YAML configuration file

```yaml
# github_api.yml
api_name: github-api
base_url: https://api.github.com
auth_type: oauth
token_url: https://github.com/login/oauth/access_token

resources:
  users:
    endpoints:
      - name: get
        method: get
        path: users/{username}
      - name: list
        method: get
        path: users
        params: true

  repos:
    endpoints:
      - name: list
        method: get
        path: repos
        params: true
      - name: get
        method: get
        path: repos/{owner}/{repo}
      - name: create
        method: post
        path: user/repos
```

### 2. Generate the API client

```bash
$ wrappix build github_api.yml
```

### 3. Use your generated API client

If generating a standalone gem:

```ruby
require 'github-api'

# Configure the client
GithubApi.configure do |config|
  config.access_token = 'your_access_token'
end

# Initialize the client
client = GithubApi.client

# Make requests
user = client.users.get('octocat')
puts user['name']
```

## Configuration Definition

The YAML configuration supports the following options:

### Global Options

| Option | Description |
|--------|-------------|
| `api_name` | Name of the API wrapper (used for file/module naming) |
| `base_url` | Base URL of the API |
| `auth_type` | Authentication type: `oauth`, `basic`, or `api_key` |

### Authentication Options

#### OAuth

```yaml
auth_type: oauth
token_url: https://example.com/oauth/token
```

#### Basic Authentication

```yaml
auth_type: basic
```

#### API Key

```yaml
auth_type: api_key
api_key_header: X-API-Key  # Header name (optional)
```

### Resources and Endpoints

```yaml
resources:
  users:  # Resource name
    endpoints:
      - name: get  # Method name
        method: get  # HTTP method (get, post, put, patch, delete)
        path: users/{id}  # Path, with parameters in braces
        params: true  # Whether it accepts query parameters (optional)
```

## Technical Details

The generated clients:

- Use Faraday to handle HTTP requests
- Have global configuration (similar to other popular gems)
- Provide error handling with detailed information
- Automatically serialize/deserialize JSON

## Contributing

Contributions are welcome:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
