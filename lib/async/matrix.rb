# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# @namespace
module Async
	# @namespace
	module Matrix
	end
end

Dir.glob("#{__dir__}/brute/**/*.rb").sort.each do |path|
  require path
end

