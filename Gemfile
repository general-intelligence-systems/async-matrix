# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

source "https://rubygems.org"

gemspec

group :test do
  gem "sus"
  gem "sus-fixtures-async"

  gem "bake-test"
end

group :lint do
  gem "rubocop"
  gem "rubocop-socketry"

  gem "decode"
end

group :release do
  gem "gem_kit-release"
end

group :benchmark do
  gem "benchmark-ips"
  gem "memory_profiler"
  gem "stackprof"
end
