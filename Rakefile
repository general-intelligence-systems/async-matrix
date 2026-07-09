# frozen_string_literal: true

require "rb_sys/extensiontask"

GEMSPEC = Gem::Specification.load("async-matrix.gemspec")

# Compiles ext/async_matrix_e2ee (Rust/magnus/vodozemac) into
# lib/async/matrix/async_matrix_e2ee.so so `require "async/matrix/e2ee"` works.
#
# RbSys::ExtensionTask (instead of the plain Rake::ExtensionTask) wires up the
# rb-sys/oxidize-rb toolchain so we can *cross-compile* precompiled, per-platform
# native gems. That is what lets `gem install async-matrix` work WITHOUT Rust:
# RubyGems downloads the fat gem matching the user's platform (which already
# contains a prebuilt .so) instead of the source gem that shells out to cargo.
RbSys::ExtensionTask.new("async_matrix_e2ee", GEMSPEC) do |ext|
  ext.ext_dir = "ext/async_matrix_e2ee"
  ext.lib_dir = "lib/async/matrix"

  # Fat gems place the compiled object in a per-Ruby-version subdir
  # (lib/async/matrix/3.3/, 3.4/, ...); e2ee.rb requires it from there.
  ext.cross_compile = true
end

# Cross-compile a precompiled gem for one platform inside the rb-sys-dock
# container, e.g. `rake native[x86_64-linux]`. CI (cross-compile.yml) drives the
# full platform matrix via oxidize-rb/actions/cross-gem.
task :native, [:platform] do |_t, args|
  platform = args[:platform] or abort "usage: rake native[<platform>]"
  sh "bundle", "exec", "rb-sys-dock", "--platform", platform, "--build"
end

task default: :compile
