# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "json"
require "async/http"

module Async
	module Matrix
		# Extends Async::HTTP::Endpoint with Matrix well-known discovery.
		# spec.matrix.org/v1.9/client-server-api/#well-known-uri
		#
		# A server at example.com may serve clients from a completely
		# different origin — e.g. https://matrix.example.com:8448.
		# #discover resolves that indirection as a proper async I/O
		# operation before constructing the Endpoint, so every downstream
		# caller gets a correctly-pointed connection pool for free.
		class Endpoint < Async::HTTP::Endpoint
			WELL_KNOWN = "/.well-known/matrix/client"

			# Resolves homeserver base URL, falls back to https://domain.
			# Must be called inside an Async block — uses the running scheduler.
			def self.discover(domain, **options)
				internet = Async::HTTP::Internet.new
				data     = JSON.parse(internet.get("https://#{domain}#{WELL_KNOWN}").read)
				base_url = data.dig("m.homeserver", "base_url") || "https://#{domain}"
				parse(base_url, **options)
			rescue StandardError
				# Well-known is optional per spec — fall back gracefully
				parse("https://#{domain}", **options)
			ensure
				internet&.close
			end
		end
	end
end

test do
	it "defines the WELL_KNOWN constant" do
		Async::Matrix::Endpoint::WELL_KNOWN.should == "/.well-known/matrix/client"
	end

	it "responds to .discover" do
		Async::Matrix::Endpoint.should.respond_to :discover
	end

	it "inherits from Async::HTTP::Endpoint" do
		Async::Matrix::Endpoint.ancestors.should.include Async::HTTP::Endpoint
	end

	it "falls back to https://domain when well-known fails" do
		Async do
			endpoint = Async::Matrix::Endpoint.discover("nonexistent.invalid")
			endpoint.to_s.should =~ /nonexistent\.invalid/
		end.wait
	end
end
