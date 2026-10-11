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

  # The library, the specification schemas it is generated from, and the native extension's sources.
  #
  # The crate ships because spec.extensions builds it at install time from the source gem, and Cargo.toml and Cargo.lock ship with it because they are the workspace root rb_sys runs `cargo metadata` from. A precompiled platform gem carries the built object instead, and builds nothing.
  #
  # The built object is rejected: `rake compile` installs one into lib/async/matrix, and that one belongs to this machine's Ruby. The source gem compiles its own, and rake-compiler puts the right one into each precompiled gem itself.
  spec.files = Dir.glob(
    ["{lib}/**/*", "{ext}/**/*.{rs,rb,toml}", "Cargo.toml", "Cargo.lock", "license.md", "readme.md", "CHANGELOG.md"],
    File::FNM_DOTMATCH,
    base: __dir__,
  ).reject{|path| File.fnmatch?("*.{so,bundle,dll,o,a}", path, File::FNM_EXTGLOB)}

  spec.require_paths = ["lib"]
  spec.extensions = ["ext/async_matrix_e2ee/extconf.rb"]

  spec.add_dependency "async-rest", "~> 0.20"
  spec.add_dependency "base64", "~> 0.3"
  spec.add_dependency "console", "~> 1.29"

  # GemKit::Deprecate declares a deprecation as a dated promise: the replacement, and the version the old name stops existing in.
  spec.add_dependency "gem_kit", "~> 0.2"

  # Wanted at install time rather than only in development: ext/async_matrix_e2ee/extconf.rb requires rb_sys/mkmf, so installing the source gem resolves this before it can compile.
  spec.add_dependency "rb_sys", "~> 0.9"

  # The Rakefile's RbSys::ExtensionTask, which `rake compile` and the cross-compile workflow drive.
  spec.add_development_dependency "rake-compiler", "~> 1.3"
  spec.add_development_dependency "lefthook", "~> 2.2"
end
