# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "lib/async/matrix/version"

Gem::Specification.new do |spec|
  spec.name = "async-matrix"
  spec.version = Async::Matrix::VERSION
  spec.authors = ["Nathan Kidd"]
  spec.email = ["nathankidd@hey.com"]
  spec.license = "Apache-2.0"

  spec.summary = "An asynchronous Ruby library for the Matrix protocol."
  spec.description = "Async-native Matrix protocol primitives built on the Socketry async ecosystem. " \
    "A resource-oriented client for every Matrix API, version by version, with schema-validated " \
    "events, media and end-to-end encryption."
  spec.homepage = "https://github.com/general-intelligence-systems/async-matrix"

  spec.required_ruby_version = ">= 3.3"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["documentation_uri"] = "https://general-intelligence-systems.github.io/async-matrix/"

  # The library, and the specification schemas it is generated from.
  #
  # This gem is pure Ruby: the vodozemac binding it used to carry is the `vodozemac` gem, which ships precompiled per platform, so nothing here is built at install time.
  #
  # `context` is the agent context specification (https://github.com/socketry/agent-context): an AI agent working on a project which depends on this gem installs these files into its own `.agents/context/async-matrix/`, so they have to reach it through the gem. bin/update-context generates them from docs/content/docs.
  #
  # LICENSE and NOTICE ship because the Apache License asks for both: section 4(a) wants every recipient given a copy of the licence, and 4(d) wants the attribution notices carried along with it.
  spec.files = Dir.glob(
    ["{context,lib}/**/*", "LICENSE", "NOTICE", "README.md", "CHANGELOG.md"],
    File::FNM_DOTMATCH,
    base: __dir__,
  )

  spec.require_paths = ["lib"]

  spec.add_dependency "async-rest", "~> 0.20"
  spec.add_dependency "base64", "~> 0.3"
  spec.add_dependency "console", "~> 1.29"

  # Olm, Megolm, SAS and the key types, as bindings over the vodozemac crate. It was `ext/async_matrix_e2ee` here until it became a gem of its own: see E2EE::Olm, E2EE::Backup and E2EE::CrossSigning::Key, which are what drive it.
  spec.add_dependency "vodozemac", "~> 0.1"

  # GemKit::Deprecate declares a deprecation as a dated promise: the replacement, and the version the old name stops existing in.
  spec.add_dependency "gem_kit", "~> 0.2"

  spec.add_development_dependency "lefthook", "~> 2.2"
end
