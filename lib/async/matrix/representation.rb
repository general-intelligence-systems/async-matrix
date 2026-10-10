# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/representation"

require_relative "wrapper"

module Async
	module Matrix
		# The base representation for all Matrix responses.
		class Representation < Async::REST::Representation[Wrapper]
		end
	end
end
