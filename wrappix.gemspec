# frozen_string_literal: true

require_relative "lib/wrappix/version"

Gem::Specification.new do |spec|
  spec.name = "wrappix"
  spec.version = Wrappix::VERSION
  spec.authors = ["Bruno Costanzo"]
  spec.email = ["dev.bcostanzo@gmail.com"]

  spec.summary = "Wrappix is a tool to create API Wrappers fast and easily"
  spec.description = "Create API Wrappers fast and easily. Wrappix provides a simple and intuitive way to create API Wrappers."
  spec.homepage = "https://github.com/bruno-costanzo/wrappix"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/bruno-costanzo/wrappix"
  spec.metadata["changelog_uri"] = "https://github.com/bruno-costanzo/wrappix/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile]) ||
        f.end_with?(".gem") # ← esta línea es la clave
    end
  end

  spec.bindir = "bin"
  spec.executables = ["wrappix"]
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"
  spec.add_dependency "faraday", ">= 1.0", "< 3.0"
  spec.add_dependency "faraday_middleware"
  spec.add_dependency "thor", "~> 1.0"
  spec.add_development_dependency "vcr", "~> 6.1"
  spec.add_development_dependency "webmock", "~> 3.18"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
