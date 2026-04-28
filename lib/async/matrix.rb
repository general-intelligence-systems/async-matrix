# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http"
require "scampi"

module Async
  module Matrix
  end
end

Dir.glob("#{__dir__}/matrix/**/*.rb").sort.each do |path|
  next if path.include?("/migrations/")
  require path
end

