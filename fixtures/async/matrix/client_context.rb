# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "sus/fixtures/async/reactor_context"

require "async/matrix"

module Async
	module Matrix
		# The homeserver to test against. The rig in `synapse/` provides one, with rate limiting
		# disabled and a module which registers a user on first login.
		HOMESERVER = ENV.fetch("MATRIX_HOMESERVER", "http://localhost:8008")
		
		# The specification version under test. `bin/test` runs the suite once per version, against a
		# server which implements that version. Deliberately not `VERSION`, which is the gem's own.
		TEST_VERSION = ENV.fetch("MATRIX_VERSION", LATEST)
		
		TEST_PASSWORD = "password"
		
		TEST_ROOM_NAME = "Test Room"
		
		TEST_ROOM_TOPIC = "Testing async-matrix"
		
		ClientContext = Sus::Shared("a matrix client") do
			include Sus::Fixtures::Async::ReactorContext
			
			let(:unauthenticated) {Async::Matrix::Client[Async::Matrix::TEST_VERSION].open(Async::Matrix::HOMESERVER)}
			
			# A fresh user and room for each test, so that tests cannot interfere with each other. The
			# rig registers a user on first login, so this needs no setup.
			let(:username) {"test-#{SecureRandom.hex(6)}"}
			
			let(:user_id) {"@#{self.username}:localhost"}
			
			let(:client) {unauthenticated.logged_in(self.username, Async::Matrix::TEST_PASSWORD)}
			
			let(:room) {client.create_room(name: Async::Matrix::TEST_ROOM_NAME, topic: Async::Matrix::TEST_ROOM_TOPIC)}
			
			# Sync until the cursor is current, so that a subsequent long poll is woken by new events
			# rather than returning events which were already pending.
			def current_sync
				sync = client.sync(timeout: 0)
				
				sync = sync.following(timeout: 0) until sync.empty?
				
				return sync
			end
			
			# Sync until a message with the given body arrives, or give up.
			#
			# A write is not necessarily visible to `/sync` the instant it completes, so a test which
			# has just written something waits for it rather than assuming the next batch contains it.
			def sync_until_message(body, attempts: 5, timeout: 2000)
				sync = client.sync(timeout: 0)
				
				attempts.times do
					if sync.each_message.any?{|_, _, message, _| message == body}
						return sync
					end
					
					sync = sync.following(timeout: timeout)
				end
				
				return nil
			end
			
			after do
				# Every resource and representation shares the client's connection, so closing the root
				# closes all of them:
				@unauthenticated&.close
			end
		end
	end
end
