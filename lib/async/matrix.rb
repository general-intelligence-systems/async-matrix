# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http"

module Async
  module Matrix
  end
end

Dir.glob("#{__dir__}/matrix/**/*.rb").sort.each do |path|
  next if path.include?("/migrations/")
  # The Discord bridge is opt-in — it pulls in Sequel and opens a placeholder
  # database at load time. Require "async/matrix/bridge/discord/db" explicitly
  # when you need it, so plain Matrix use stays free of that dependency.
  next if path.include?("/bridge/")
  require path
end

