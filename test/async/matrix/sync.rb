# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "securerandom"

require "async/matrix/client_context"

describe Async::Matrix::Sync do
	include Async::Matrix::ClientContext
	
	with "an initial sync" do
		it "reports a batch token" do
			sync = client.sync(timeout: 0)
			
			expect(sync.next_batch).to be_a(String)
		end
		
		it "includes rooms the user has joined" do
			room
			
			sync = client.sync(timeout: 0)
			
			expect(sync.joined).to be(:key?, room.id.to_sym)
		end
		
		it "enumerates timeline events with their room id" do
			body = "synced"
			
			room.send_message(body)
			
			sync = sync_until_message(body)
			
			expect(sync).not.to be_nil
			
			# Room IDs are symbols in the parsed payload, and are converted back to strings:
			events = sync.each_event.select{|room_id, _| room_id == room.id}
			
			expect(events).not.to be(:empty?)
			expect(events.first.first).to be_a(String)
		end
		
		it "enumerates messages" do
			body = "a message"
			
			room.send_message(body)
			
			sync = sync_until_message(body)
			
			expect(sync).not.to be_nil
			
			messages = sync.each_message.select{|room_id, _, _, _| room_id == room.id}
			
			expect(messages.map{|_, _, message, _| message}).to be(:include?, body)
		end
	end
	
	with "#following" do
		it "is woken by an event sent while the request is in flight" do
			body = "woke the long poll"
			
			# Create the room first: otherwise the long poll is woken by the room creation itself, and
			# returns a batch which does not contain the message yet.
			room
			
			# Establish a current cursor, so the long poll is woken rather than returning immediately:
			sync = current_sync
			
			writer = Async do
				sleep 0.2
				room.send_message(body)
			end
			
			following = sync.following(timeout: 10_000)
			
			expect(following.each_message.map{|_, _, message, _| message}).to be(:include?, body)
		ensure
			writer&.wait
		end
		
		it "continues from the previous batch" do
			room
			
			sync = current_sync
			
			room.send_message("next batch")
			
			following = sync.following(timeout: 5000)
			
			expect(following.next_batch).not.to be == sync.next_batch
		end
	end
end
