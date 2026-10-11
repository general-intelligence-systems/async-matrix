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

# Separate from :test, because the cops cannot be installed everywhere the suite can run.
#
# The gemspec asks for Ruby 3.3, and the suite does run there. ast-crispr-ruby-prism does not: it has only ever been released at 7.1.x, and that line - along with ast-crispr, ast-merge, prism-merge and tree_haver 7 beneath it - requires Ruby 4, so there is no older version to hold back to. Keeping it in :test made `bundle install` fail on Ruby 3.3 before a test could run.
#
# So linting is a group of its own, which a job that only wants to run the suite leaves out with BUNDLE_WITHOUT. `bin/rubocop` needs Ruby 4, which is the Ruby it is run on.
group :lint do
  gem "rubocop"
  gem "rubocop-socketry"

  # Local/CommentStructure parses comments with decode, so that an annotation is whatever decode recognises as one rather than whatever a regular expression here happens to match.
  gem "decode"

  # The cops read the file with Prism rather than the parser gem RuboCop hands them: ast-crispr-ruby-prism resolves which comment documents which declaration, and tree_haver walks the tree uniformly.
  gem "ast-crispr-ruby-prism"
end

# bin/update-spec reads the matrix-spec submodules, whose schemas are full of $ref - including pointers into other documents. json_schemer resolves them.
group :maintenance do
  gem "json_schemer"
end

# The maintainer's half of gem_kit, which the published gem has no use for: one RubyGems command, `gem kit`, for bumping the version, writing and linting the changelog, listing the outstanding deprecations, releasing and tagging.
#
# It keeps the promises `gem_kit` records, so a bump refuses to move onto a deprecation's removal version while the deprecated name is still there.
group :release do
  gem "gem_kit-release"
end

# The benchmarks, which are a group of their own for the reason the cops are: a run of the suite has no use for them, and a job which only wants to run the suite leaves them out with BUNDLE_WITHOUT.
#
# Only the harnesses need gems, one each. The default harness times with `Process.clock_gettime` and counts with `GC.stat`, and writes its own results, so a benchmark can be run with nothing installed beyond what the suite already needs.
group :benchmark do
  # harness-bips, which measures a rate rather than a time.
  gem "benchmark-ips"

  # harness-memory, which says what was allocated and what was kept, by file and by class.
  gem "memory_profiler"

  # harness-stackprof, which says where the time went.
  gem "stackprof"
end
