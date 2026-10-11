# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "harness"

require "json"
require "rbconfig"

# What it costs a program to require the library, which is the first number anybody who depends on the gem feels.
#
# A fresh child per iteration, because `require` happens once per process: a second one in this process would measure nothing. The time the harness reports therefore includes starting a Ruby, and the `load` figure recorded beside it is the child's own measurement of the require alone.

# The program the child runs, which measures itself and prints what it found.
SUBJECT = File.expand_path("subject.rb", __dir__)

# The library under test, which is this working copy rather than an installed gem.
LIBRARY = File.expand_path("../../lib", __dir__)

run_benchmark do
  output = IO.popen([RbConfig.ruby, "-I", LIBRARY, SUBJECT], &:read)

  JSON.parse(output, symbolize_names: true)
end
