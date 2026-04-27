# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/http"

module Async
	module Matrix
		class Client < Async::HTTP::Protocol::HTTP2::Client
		end
	end
end

test do
	it "inherits from Async::HTTP::Protocol::HTTP2::Client" do
		Async::Matrix::Client.ancestors.should.include Async::HTTP::Protocol::HTTP2::Client
	end
end
