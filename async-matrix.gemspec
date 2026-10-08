# frozen_string_literal: true

require_relative "lib/async/matrix/version"

Gem::Specification.new do |spec|
	spec.name = "async-matrix"
	spec.version = Async::Matrix::VERSION
	spec.authors = ["Nathan Kidd"]
	spec.email = ["nathankidd@hey.com"]
	spec.license = "Apache-2.0"

	spec.summary = "An asynchronous Ruby library for the Matrix protocol."
	spec.description = "Async-native Matrix protocol primitives built on the Socketry async ecosystem. " \
		"Provides a Client-Server API client, schema-validated events, media and end-to-end encryption."
	spec.homepage = "https://github.com/general-intelligence-systems/async-matrix"

	spec.required_ruby_version = ">= 3.3"

	spec.metadata["homepage_uri"] = spec.homepage
	spec.metadata["source_code_uri"] = spec.homepage
	spec.metadata["documentation_uri"] = "https://general-intelligence-systems.github.io/async-matrix/"

	spec.files = Dir["lib/**/*.rb", "lib/**/*.json", "data/**/*.yaml", "data/**/*.json", "ext/**/*.{rs,rb,toml}", "Cargo.toml", "Cargo.lock", "LICENSE", "README.md"]
	spec.require_paths = ["lib"]
	spec.extensions = ["ext/async_matrix_e2ee/extconf.rb"]

	spec.add_dependency "async", "~> 2.46"
	spec.add_dependency "async-http", "~> 0.105"
	spec.add_dependency "json_schemer", "~> 2.5"
  spec.add_dependency "string_builder", "~> 1.2"

  spec.add_dependency "rb_sys", "~> 0.9"

  spec.add_development_dependency "scampi", "~> 1.0"
  spec.add_development_dependency "logger"
  spec.add_development_dependency "rake-compiler", "~> 1.3"
  spec.add_development_dependency "lefthook", "~> 2.2"
end
