# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/http"
require "scampi"

module Async
  module Discord
  end
end

Dir.glob("#{__dir__}/discord/**/*.rb").sort.each do |path|
  require path
end
