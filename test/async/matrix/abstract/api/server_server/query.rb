# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for what a server will tell another about a user or an alias, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ServerServer
          # Cases for {ruby Async::Matrix::ServerServer::Query}.
          module Query
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # v1.16 let a profile carry unnamed fields.
            module V1_16
              def self.included(base)
                base.it "reads a field the specification does not name" do
                  client.profile.set_profile_field(member, "m.tz", "Europe/London")

                  expect(server.query.query_profile(member).field("m.tz")).to be == "Europe/London"
                end
              end
            end

            # No changes in v1.15.
            module V1_15
            end

            # No changes in v1.14.
            module V1_14
            end

            # No changes in v1.13.
            module V1_13
            end

            # No changes in v1.12.
            module V1_12
            end

            # No changes in v1.11.
            module V1_11
            end

            # No changes in v1.10.
            module V1_10
            end

            # No changes in v1.9.
            module V1_9
            end

            # No changes in v1.8.
            module V1_8
            end

            # No changes in v1.7.
            module V1_7
            end

            # No changes in v1.6.
            module V1_6
            end

            # No changes in v1.5.
            module V1_5
            end

            # No changes in v1.4.
            module V1_4
            end

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 asked a server about a user and an alias.
            module V1_1
              def self.included(base)
                # Asking for the user ID through the client is what makes the account: a server has nothing to say about a user who was never registered.
                base.let(:member){client.get_token_owner.user_id}

                # An alias has to be asked for when the room is made: there is nothing to resolve otherwise.
                base.let(:localpart){"fed-#{SecureRandom.hex(6)}"}

                base.let(:room_alias){"##{localpart}:#{server_name}"}

                base.let(:aliased){client.create_room(room_alias_name: localpart, preset: "public_chat")}

                # A new account is given the display name of its localpart, so there is one to read without setting it - which matters, because v1.16 withdrew the operation which set it.
                base.it "can queryProfile" do
                  expect(server.query.query_profile(member).displayname).not.to be_nil
                end

                base.it "asks for one field of a profile" do
                  expect(server.query.query_profile(member, field: "displayname").displayname).not.to be_nil
                end

                base.it "can queryRoomDirectory" do
                  created = aliased

                  entry = server.query.query_room_directory(room_alias)

                  expect(entry.room_id).to be == created.id
                  expect(entry.servers).to be(:include?, server_name)
                end

                base.it "can queryInfo" do
                  expect(server.query.query_info("profile", user_id: member).field("displayname")).not.to be_nil
                end

                # The profile of a user nobody has heard of is not a profile with nothing in it.
                base.it "refuses a profile which does not exist" do
                  expect do
                    server.query.query_profile("@nobody-at-all:#{server_name}").displayname
                  end.to raise_exception(Async::Matrix::RequestError)
                end

                base.it "refuses an alias which names nothing" do
                  expect do
                    server.query.query_room_directory("#nothing-at-all:#{server_name}").room_id
                  end.to raise_exception(Async::Matrix::RequestError)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("query cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Query.const_defined?(name, false)
                  include Query.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
