# frozen_string_literal: true

require_relative "lib/async/matrix/version"

Gem::Specification.new do |spec|
  spec.name = "async-matrix"
  spec.version = Async::Matrix::VERSION

  spec.summary = "A client for the Matrix client-server API."
  spec.authors = ["Nathan K"]
  spec.license = "MIT"

  spec.homepage = "https://github.com/socketry/async-matrix"

  spec.metadata = {
    "source_code_uri" => "https://github.com/socketry/async-matrix.git",
  }

  spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)

  spec.required_ruby_version = ">= 3.3"

  spec.add_dependency "async-rest", "~> 0.20"
  spec.add_dependency "base64", "~> 0.3"
end
