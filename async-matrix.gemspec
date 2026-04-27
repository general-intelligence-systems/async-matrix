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
		"Provides well-known discovery, event notification, and application service models."
	spec.homepage = "https://github.com/general-intelligence-systems/async-matrix"

	spec.required_ruby_version = ">= 3.3"

	spec.metadata["homepage_uri"] = spec.homepage
	spec.metadata["source_code_uri"] = spec.homepage

	spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md"]
	spec.require_paths = ["lib"]

	spec.add_dependency "async", "~> 2.0"
	spec.add_dependency "async-http", "~> 0.69"
end
