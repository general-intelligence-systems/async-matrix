# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/operations_context"

# Cases for the key backup operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module KeyBackup
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
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

            # v1.2 renamed the session operations.
            module V1_2
              def self.included(base)
                base.it "can putRoomKeyBySessionId" do
                  expect(keys.put_session(room.id, "session", session_data: session_data).count).to be == 1
                end

                base.it "can getRoomKeyBySessionId" do
                  keys.put_session(room.id, "session", session_data: session_data)

                  expect(keys.of_session(room.id, "session").session_data[:ciphertext]).to be == "cipher"
                end

                base.it "can deleteRoomKeyBySessionId" do
                  keys.put_session(room.id, "session", session_data: session_data)

                  expect(keys.delete_session(room.id, "session").count).to be == 0
                end
              end
            end

            # v1.1 carries the version and room cases.
            module V1_1
              def self.included(base)
                # One version, for the cases which need one.
                base.let(:backup) do
                  client.key_backup.create(algorithm: "m.megolm_backup.v1.curve25519-aes-sha2", auth_data: {public_key: "abc"})
                end

                base.let(:keys){client.key_backup.keys(backup.version)}

                base.let(:session_data){{ciphertext: "cipher", mac: "mac", ephemeral: "ephemeral"}}

                base.it "can postRoomKeysVersion" do
                  expect(backup.version).to be_a(String)
                end

                base.it "can getRoomKeysVersionCurrent" do
                  backup

                  expect(client.key_backup.current.version).to be == backup.version
                end

                base.it "can getRoomKeysVersion" do
                  expect(client.key_backup.describe(backup.version).algorithm).to be == "m.megolm_backup.v1.curve25519-aes-sha2"
                end

                base.it "can putRoomKeysVersion" do
                  client.key_backup.update(backup.version, algorithm: "m.megolm_backup.v1.curve25519-aes-sha2", auth_data: {public_key: "def"})

                  expect(client.key_backup.describe(backup.version).auth_data[:public_key]).to be == "def"
                end

                base.it "can deleteRoomKeysVersion" do
                  version = backup.version

                  client.key_backup.delete(version)

                  error = nil

                  begin
                    client.key_backup.describe(version)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error).to be_a(Async::Matrix::RequestError)
                end

                base.it "can putRoomKeys" do
                  rooms = {room.id => {sessions: {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}}}

                  expect(keys.put(rooms).count).to be == 1
                end

                base.it "can getRoomKeys" do
                  keys.put({room.id => {sessions: {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}}})

                  expect(keys.all.sessions_of(room.id).keys.map(&:to_s)).to be(:include?, "session")
                end

                base.it "can deleteRoomKeys" do
                  keys.put({room.id => {sessions: {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}}})

                  expect(keys.delete.count).to be == 0
                end

                base.it "can putRoomKeysByRoomId" do
                  sessions = {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}

                  expect(keys.put_room(room.id, sessions).count).to be == 1
                end

                base.it "can getRoomKeysByRoomId" do
                  keys.put_room(room.id, {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}})

                  expect(keys.of_room(room.id).ids).to be(:include?, "session")
                end

                base.it "can deleteRoomKeysByRoomId" do
                  keys.put_room(room.id, {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}})

                  expect(keys.delete_room(room.id).count).to be == 0
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("key backup cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if KeyBackup.const_defined?(name, false)
                  include KeyBackup.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
