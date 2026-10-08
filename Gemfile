# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# Maintainer-only release tooling (`gem kit bump`, `gem kit release`), plus the
# deprecation DSL the release gates read. Lives here rather than in the
# gemspec: nobody installing async-matrix — or contributing to it — needs the
# release toolchain to build or test the gem.
gem "gem_kit", "~> 0.2"
gem "gem_kit-release", "~> 0.3"
gem "rubocop"
