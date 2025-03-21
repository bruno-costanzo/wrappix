# Wrappix

Wrappix is a code generator that creates Ruby API client libraries from a YAML configuration file. It helps you build structured wrappers for REST APIs with minimal effort.

## Features

- **Complete code generation**: Creates all classes and methods needed to interact with a REST API
- **Configurable**: Define resources, endpoints, and parameters in a simple YAML file
- **Multiple authentication types**: Supports OAuth, Basic Authentication, and API Keys
- **Automatic documentation**: Generates README with usage examples and detailed API reference
- **Error handling**: Integrated HTTP error management with detailed error objects
- **Smart object mapping**: Converts JSON responses into Ruby objects with nested attribute access
- **Built-in caching**: Optional caching system for authentication tokens
- **Elegant interface**: Fluent API inspired by Ruby best practices

## Installation

Add this line to your Gemfile:

```ruby
gem 'wrappix'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install wrappix
```

## Usage

Wrappix can be used in two primary ways:

1. Generate a standalone API wrapper gem
2. Create an API client within an existing project

### Quick Start

#### 1. Create a YAML configuration file

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

#### 2. Generate the API client

```bash
$ wrappix build github_api.yml
```

#### 3. Use your generated API client

```ruby
require 'github_api'  # Note: require with underscore!

# Configure the client
GithubApi.configure do |config|
  config.client_id = "your_client_id"
  config.client_secret = "your_client_secret"
  config.access_token = "your_access_token"
end

# Initialize the client
client = GithubApi.client

# Get a user
user = client.users.get("octocat")
puts user.name
puts user.location
puts user.public_repos

# List repositories with pagination
repos = client.repos.list({page: 1, per_page: 10})
repos.data.each do |repo|
  puts "#{repo.name}: #{repo.description}"
end

# Check if there are more pages
if repos.next_href
  puts "More repositories available"
end
```

## Configuration Reference

The YAML configuration file supports the following options:

### Global Options

| Option | Description | Required | Default |
|--------|-------------|----------|---------|
| `api_name` | Name of the API wrapper (used for file/module naming) | Yes | |
| `base_url` | Base URL of the API | Yes | |
| `auth_type` | Authentication type: `oauth`, `basic`, or `api_key` | No | None |
| `response_format` | Configuration for response mapping (see below) | No | Auto-detect |

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
api_key_header: X-API-Key  # Custom header name (optional)
```

### Resources and Endpoints

Resources define the API endpoints that will be available in your client:

```yaml
resources:
  users:  # Resource name
    endpoints:
      - name: get            # Method name in your code
        method: get          # HTTP method (get, post, put, patch, delete)
        path: users/{id}     # Path with parameters in braces
        params: true         # Whether it accepts query parameters (optional)
        collection: false    # Whether it returns a collection (optional)

      - name: list
        method: get
        path: users
        params: true
        collection: true     # Processes response as a collection
```

### Response Format Configuration

You can configure how responses are mapped to objects:

```yaml
response_format:
  collection_root: "data"    # JSON key containing the collection items
  item_root: "user"          # JSON key containing single items (optional)
  pagination:
    next_page_key: "next_href"   # JSON key with URL to next page
    total_count_key: "total"     # JSON key with total count
    limit_key: "limit"           # JSON key with page size
```

## Generated Client Architecture

The generated client follows a clean architecture pattern:

- `Client`: Main entry point to the API
- `Resources`: Classes for each resource (users, repos, etc.)
- `Request`: Handles HTTP communication
- `Object`: Maps JSON responses to Ruby objects
- `Collection`: Handles collections of objects with pagination
- `Error`: Standardized error handling
- `Configuration`: Global configuration

## Customization

After generating your API client, you can further customize it by editing the generated files.

## Contributing

Contributions are welcome:

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
