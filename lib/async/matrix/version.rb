# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"

module Async
	module Matrix
		VERSION = "0.1.0"
	end
end

test do
	it "is defined" do
		Async::Matrix::VERSION.should.not.be.nil
	end

	it "is a string" do
		Async::Matrix::VERSION.should.be.kind_of String
	end

	it "follows semver format" do
		Async::Matrix::VERSION.should =~ /\A\d+\.\d+\.\d+\z/
	end
end
