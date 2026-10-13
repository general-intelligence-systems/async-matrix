# frozen_string_literal: true

require "async/matrix"
require "async/matrix/e2ee"
require "digest"
require "openssl"

module Matrix
  module Device
    OLM_DUMP = "olm_dump"

    SESSION_DUMP = "megolm_sessions"

    module Crypto
      module_function

      def pickle_key
        @pickle_key ||= Digest::SHA256.hexdigest(ENV.fetch("MATRIX_ENCRYPTION_KEY"))[0, 32]
      end
    end

    module_function

    def crypto
      self.machine.crypto
    end

    def restore
      credential = Models::Matrix::Credential.first
      dumped = Models::Matrix::KV[OLM_DUMP]

      unless dumped.to_s.empty?
        Async::Matrix::E2EE::Machine.load(
          dumped,
          Crypto.pickle_key,
          user_id:   credential&.matrix_user_id.to_s,
          device_id: credential&.device_id.to_s,
          crypto:    Async::Matrix::E2EE::Olm,
          version:   Homeserver::VERSION,
        )
      end
    rescue Async::Matrix::MismatchedAccountError => error
      Console.warn(self, "The stored device belongs to another session.", expected: error.expected, got: error.got)

      self.discard!

      nil
    rescue StandardError => error
      Console.warn(self, "Could not read the stored device.", error: error)

      nil
    end

    def fresh
      credential = Models::Matrix::Credential.first

      Async::Matrix::E2EE::Machine.new(
        user_id:   credential&.matrix_user_id.to_s,
        device_id: credential&.device_id.to_s,
        crypto:    Async::Matrix::E2EE::Olm.new,
        version:   Homeserver::VERSION,
      )
    end

    def discard!
      Models::Matrix::KV.unset!(OLM_DUMP)
      Models::Matrix::KV.unset!(SESSION_DUMP)
      Models::Matrix::KV.unset!(Models::Matrix::KV::SYNC_TOKEN)
    end

    def persist!
      Models::Matrix::KV.set!(OLM_DUMP, self.machine.dump(Crypto.pickle_key))
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
      @machine ||= self.adopt!(self.remember!(self.restore || self.fresh))
    end

    def adopt!(machine)
      Models::Matrix::SecretsInbox.all.each do |row|
        machine.secrets.accept(row.secret_name, row.secret)

        if Matrix::Crypto::CROSS_SIGNING.include?(row.secret_name)
          machine.accept_cross_signing_secret(row.secret_name, row.secret)
        end
      end

      machine
    end

    def forget!
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
      target = machine.crypto.one_time_key_target

      machine.crypto.generate_one_time_keys(target)
      machine.crypto.generate_fallback_key

      answer = client.keys.upload_keys(
        device_keys:   machine.device_keys,
        one_time_keys: machine.signed_one_time_keys,
        fallback_keys: machine.signed_fallback_key,
      )

      self.published!(answer, keys_published: true)

      answer
    end

    def replace_fallback_key!(client, listed)
      unless listed.nil? || listed.include?("signed_curve25519")
        machine = self.machine

        machine.crypto.generate_fallback_key
        client.keys.upload_keys(fallback_keys: machine.signed_fallback_key)
        self.persist!

        Console.info(self, "Replaced the fallback key, which had been claimed.")
      end
    end

    def top_up_keys!(client, held)
      machine = self.machine
      target = machine.crypto.one_time_key_target

      if held < target / 2
        machine.crypto.generate_one_time_keys(target - held)

        answer = client.keys.upload_keys(one_time_keys: machine.signed_one_time_keys)

        Console.info(self, "Topped up the one time keys.", held: held, now: answer.count("signed_curve25519"))
        self.published!(answer)

        answer
      end
    end

    def published!(answer, **fields)
      self.crypto.published_one_time_keys!
      self.persist!

      row = self.state
      row.set(otk_count: answer.count("signed_curve25519"), **fields)
      row.save_changes(validate: false)
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
