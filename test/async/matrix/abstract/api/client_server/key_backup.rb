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
                  expect(keys.put_room_key_by_session_id(room.id, "session", session_data: session_data).count).to be == 1
                end

                base.it "can getRoomKeyBySessionId" do
                  keys.put_room_key_by_session_id(room.id, "session", session_data: session_data)

                  expect(keys.get_room_key_by_session_id(room.id, "session").session_data[:ciphertext]).to be == "cipher"
                end

                base.it "can deleteRoomKeyBySessionId" do
                  keys.put_room_key_by_session_id(room.id, "session", session_data: session_data)

                  expect(keys.delete_room_key_by_session_id(room.id, "session").count).to be == 0
                end
              end
            end

            # v1.1 carries the version and room cases.
            module V1_1
              def self.included(base)
                # One version, for the cases which need one.
                base.let(:backup) do
                  client.key_backup.post_room_keys_version(algorithm: "m.megolm_backup.v1.curve25519-aes-sha2", auth_data: {public_key: "abc"})
                end

                base.let(:keys){client.key_backup.keys(backup.version)}

                base.let(:session_data){{ciphertext: "cipher", mac: "mac", ephemeral: "ephemeral"}}

                base.it "can postRoomKeysVersion" do
                  expect(backup.version).to be_a(String)
                end

                base.it "can getRoomKeysVersionCurrent" do
                  backup

                  expect(client.key_backup.get_room_keys_version_current.version).to be == backup.version
                end

                base.it "can getRoomKeysVersion" do
                  expect(client.key_backup.get_room_keys_version(backup.version).algorithm).to be == "m.megolm_backup.v1.curve25519-aes-sha2"
                end

                base.it "can putRoomKeysVersion" do
                  client.key_backup.put_room_keys_version(backup.version, algorithm: "m.megolm_backup.v1.curve25519-aes-sha2", auth_data: {public_key: "def"})

                  expect(client.key_backup.get_room_keys_version(backup.version).auth_data[:public_key]).to be == "def"
                end

                base.it "can deleteRoomKeysVersion" do
                  version = backup.version

                  client.key_backup.delete_room_keys_version(version)

                  error = nil

                  begin
                    client.key_backup.get_room_keys_version(version)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error).to be_a(Async::Matrix::RequestError)
                end

                base.it "can putRoomKeys" do
                  rooms = {room.id => {sessions: {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}}}

                  expect(keys.put_room_keys(rooms).count).to be == 1
                end

                base.it "can getRoomKeys" do
                  keys.put_room_keys({room.id => {sessions: {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}}})

                  expect(keys.get_room_keys.sessions_of(room.id).keys.map(&:to_s)).to be(:include?, "session")
                end

                base.it "can deleteRoomKeys" do
                  keys.put_room_keys({room.id => {sessions: {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}}})

                  expect(keys.delete_room_keys.count).to be == 0
                end

                base.it "can putRoomKeysByRoomId" do
                  sessions = {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}}

                  expect(keys.put_room_keys_by_room_id(room.id, sessions).count).to be == 1
                end

                base.it "can getRoomKeysByRoomId" do
                  keys.put_room_keys_by_room_id(room.id, {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}})

                  expect(keys.get_room_keys_by_room_id(room.id).ids).to be(:include?, "session")
                end

                base.it "can deleteRoomKeysByRoomId" do
                  keys.put_room_keys_by_room_id(room.id, {"session" => {session_data: session_data, first_message_index: 0, forwarded_count: 0, is_verified: false}})

                  expect(keys.delete_room_keys_by_room_id(room.id).count).to be == 0
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

          # Cases for {ruby Async::Matrix::ClientServer::BackupKeys}, whose session operations v1.2 renamed.
          module BackupKeys
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

            # No changes in v1.2.
            module V1_2
            end

            # v1.1 named the single session operations in the plural.
            module V1_1
              # The operations these cases exercise are gone from v1.2, and so are the cases.
              WITHDRAWN_IN = "v1.2"

              def self.included(base)
                base.it "can putRoomKeysBySessionId" do
                  expect(keys.put_room_keys_by_session_id(room.id, "session", session_data: session_data).count).to be == 1
                end

                base.it "can getRoomKeysBySessionId" do
                  keys.put_room_keys_by_session_id(room.id, "session", session_data: session_data)

                  expect(keys.get_room_keys_by_session_id(room.id, "session").session_data[:ciphertext]).to be == "cipher"
                end

                base.it "can deleteRoomKeysBySessionId" do
                  keys.put_room_keys_by_session_id(room.id, "session", session_data: session_data)

                  expect(keys.delete_room_keys_by_session_id(room.id, "session").count).to be == 0
                end
              end
            end

            # The cases required at the version under test.
            #
            # A layer whose operations a later version withdrew names that version, and is left out once the version under test has reached it: the cases go the way the operations did.
            CASES = Sus::Shared("backup keys cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if BackupKeys.const_defined?(name, false)
                  layer = BackupKeys.const_get(name, false)

                  if layer.const_defined?(:WITHDRAWN_IN, false) and Async::Matrix::Versions.up_to(Async::Matrix::TEST_VERSION).include?(layer::WITHDRAWN_IN)
                    next
                  end

                  include layer
                end
              end
            end
          end
        end
      end
    end
  end
end
