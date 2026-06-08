# frozen_string_literal: true

require "rake/extensiontask"

# Compiles ext/async_matrix_e2ee (Rust/magnus) into
# lib/async/matrix/async_matrix_e2ee.so so `require "async/matrix/e2ee"` works.
Rake::ExtensionTask.new("async_matrix_e2ee") do |ext|
  ext.ext_dir = "ext/async_matrix_e2ee"
  ext.lib_dir = "lib/async/matrix"
end

task default: :compile
