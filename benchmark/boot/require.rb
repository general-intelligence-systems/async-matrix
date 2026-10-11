# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "harness"

require "json"
require "rbconfig"

# What it costs a program to require the library, which is the first number anybody who depends on the gem feels.
#
# A fresh child per iteration, because `require` happens once per process: a second one in this process would measure nothing. The time the harness reports therefore includes starting a Ruby, and the `load` figure recorded beside it is the child's own measurement of the require alone.

# The program the child runs, which measures itself and prints what it found.
SUBJECT = File.expand_path("subject.rb", __dir__)

run_benchmark do
  # LIBRARY rather than this file's own directory, so that a comparison loads the revision under test rather than always this one:
  output = IO.popen([RbConfig.ruby, "-I", LIBRARY, SUBJECT], &:read)

  JSON.parse(output, symbolize_names: true)
end
