# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

source "https://rubygems.org"

gemspec

group :test do
  gem "sus"
  gem "sus-fixtures-async"

  gem "rubocop"
  gem "rubocop-socketry"

  # Local/CommentStructure parses comments with decode, so that an annotation is whatever decode recognises as one rather than whatever a regular expression here happens to match.
  gem "decode"

  # The cops read the file with Prism rather than the parser gem RuboCop hands them: ast-crispr-ruby-prism resolves which comment documents which declaration, and tree_haver walks the tree uniformly.
  gem "ast-crispr-ruby-prism"

  gem "bake-test"
end

# bin/update-spec reads the matrix-spec submodules, whose schemas are full of $ref - including pointers into other documents. json_schemer resolves them.
group :maintenance do
  gem "json_schemer"
end
