# frozen_string_literal: true

require "async/matrix"
require "async/matrix/e2ee"
require "digest"
require "openssl"

module Matrix
  module Device
    OLM_DUMP = "olm_dump"

    SESSION_DUMP = "megolm_sessions"

    OTK_TARGET = 50

    ATTEMPTS = 4

    module Crypto
      module_function

      def pickle_key
        @pickle_key ||= Digest::SHA256.hexdigest(ENV.fetch("MATRIX_ENCRYPTION_KEY"))[0, 32]
      end
    end

    module_function

    def crypto
      @crypto ||= self.restore || Async::Matrix::E2EE::Olm.new
    end

    def restore
      dumped = Models::Matrix::KV[OLM_DUMP]

      unless dumped.to_s.empty?
        Async::Matrix::E2EE::Olm.load(dumped, Crypto.pickle_key)
      end
    rescue StandardError => error
      Console.warn(self, "Could not read the stored device.", error: error)

      nil
    end

    def persist!
      Models::Matrix::KV.set!(OLM_DUMP, self.crypto.dump(Crypto.pickle_key))
      Models::Matrix::KV.set!(SESSION_DUMP, self.remembered)
    end

    def remembered
      self.machine.store.sessions.map do |(room_id, session_id), held|
        {
          "room_id" => room_id,
          "session_id" => session_id,
          "sender" => held[:sender],
          "imported" => held[:imported],
          "first_known_index" => held[:first_known_index],
          "device_id" => held[:device_id],
          "shareable" => held[:shareable],
        }
      end
    end

    def remember!(machine)
      Models::Matrix::KV[SESSION_DUMP].to_a.each do |held|
        machine.store.remember(
          held["room_id"],
          session_id:        held["session_id"],
          sender:            held["sender"],
          imported:          held["imported"],
          first_known_index: held["first_known_index"],
          device_id:         held["device_id"],
          shareable:         held["shareable"],
        )
      end

      machine
    end

    def machine
      credential = Models::Matrix::Credential.first

      @machine ||= self.remember!(
        Async::Matrix::E2EE::Machine.new(
          user_id:   credential&.matrix_user_id.to_s,
          device_id: credential&.device_id.to_s,
          crypto:    self.crypto,
          version:   Homeserver::VERSION,
        ),
      )
    end

    def forget!
      @crypto = nil
      @machine = nil
    end

    def state
      Models::Matrix::DeviceState.first ||
        Models::Matrix::DeviceState.new(account_pickle: "-").save(validate: false)
    end

    def identity_keys
      self.crypto.identity_keys
    end

    def fingerprint
      self.identity_keys[:ed25519].to_s
    end

    def publish_keys!(client)
      machine = self.machine

      answer = client.keys.upload_keys(device_keys: machine.device_keys)

      self.persist!

      row = self.state
      row.set(keys_published: true)
      row.save_changes(validate: false)

      self.publish_one_time_keys!(client)

      answer
    end

    def publish_one_time_keys!(client, attempts: ATTEMPTS)
      machine = self.machine

      machine.crypto.generate_one_time_keys(OTK_TARGET)

      answer = client.keys.upload_keys(one_time_keys: machine.signed_one_time_keys)

      self.spent!

      self.state.set(otk_count: answer.count("signed_curve25519")).save_changes(validate: false)

      answer
    rescue Async::Matrix::RequestError => error
      if attempts > 1 && error.message.include?("already exists")
        Console.warn(self, "The server holds a key under an ID this device just minted.", attempts: attempts)

        self.spent!

        self.publish_one_time_keys!(client, attempts: attempts - 1)
      else
        raise
      end
    end

    def spent!
      self.crypto.published_one_time_keys!
      self.persist!
    end

    def published?
      self.state.keys_published
    end

    def secrets
      self.machine.secrets
    end

    def describe_storage!
      default = Models::Matrix::AccountData.content_for(event_type: Matrix::Crypto::DEFAULT_KEY).to_h
      key_id = default["key"].to_s

      unless key_id.empty?
        description = Models::Matrix::AccountData
          .content_for(event_type: "m.secret_storage.key.#{key_id}").to_h

        self.secrets.describe(key_id, self.symbolized(description))

        Matrix::Crypto::SECRETS.each do |name|
          sealed = Models::Matrix::AccountData.content_for(event_type: name).to_h["encrypted"]

          unless sealed.nil?
            self.secrets.sealed(name, self.symbolized(sealed))
          end
        end
      end

      key_id
    end

    def symbolized(value)
      case value
      in Hash => hash
        hash.each_with_object({}){|(key, held), done| done[key.to_sym] = self.symbolized(held)}
      else
        value
      end
    end
  end
end
