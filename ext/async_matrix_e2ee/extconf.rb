# frozen_string_literal: true

require "mkmf"
require "rb_sys/mkmf"

# Builds the Rust crate in this directory and produces async_matrix_e2ee.so.
# The crate's #[magnus::init] defines the classes under Async::Matrix::E2EE.
create_rust_makefile("async_matrix_e2ee")
