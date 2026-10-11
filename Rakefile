# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "rb_sys/extensiontask"

GEMSPEC = Gem::Specification.load("async-matrix.gemspec")

# Compiles ext/async_matrix_e2ee, the Rust crate over vodozemac, into lib/async/matrix/async_matrix_e2ee.so.
#
# Nothing under lib/ requires it yet: E2EE::Crypto is the interface encryption is written against, and E2EE::Plaintext is the only implementation the library ships. The crate is the binding a real implementation will be built on, and the toolchain is kept wired up so that the release already ships precompiled gems on the day one is.
#
# RbSys::ExtensionTask rather than the plain Rake::ExtensionTask, because it wires up the rb-sys toolchain which cross-compiles precompiled per-platform gems. That is what lets `gem install async-matrix` want no Rust: RubyGems serves the gem matching the platform, whose object is already built, rather than the source gem which shells out to cargo.
RbSys::ExtensionTask.new("async_matrix_e2ee", GEMSPEC) do |ext|
  ext.ext_dir = "ext/async_matrix_e2ee"
  ext.lib_dir = "lib/async/matrix"

  # A precompiled gem carries one object per Ruby version, under lib/async/matrix/3.3, 3.4 and so on.
  ext.cross_compile = true
end

# Cross-compile one platform's gem inside the rb-sys-dock container, as `rake native[x86_64-linux]`. CI drives the whole matrix through oxidize-rb/actions/cross-gem: see .github/workflows/cross-compile.yml.
task :native, [:platform] do |_task, arguments|
  platform = arguments[:platform] or abort "usage: rake native[<platform>]"

  sh "bundle", "exec", "rb-sys-dock", "--platform", platform, "--build"
end

task default: :compile
