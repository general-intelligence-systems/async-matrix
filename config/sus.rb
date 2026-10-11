# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

begin
  require "covered/sus"
  include Covered::Sus
rescue LoadError
  # Coverage is optional.
end
