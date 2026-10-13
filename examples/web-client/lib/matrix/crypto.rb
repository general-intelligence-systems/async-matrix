# frozen_string_literal: true

require "async/matrix"
require "async/matrix/e2ee"
require "base64"
require "multi_json"
require "openssl"
require "securerandom"

require_relative "room_actions"
require_relative "device"
require_relative "session"

module Matrix
  module Crypto
    class Error < RoomActions::Error
    end

    DEFAULT_KEY = "m.secret_storage.default_key"

    MASTER = "m.cross_signing.master"

    SELF_SIGNING = "m.cross_signing.self_signing"

    USER_SIGNING = "m.cross_signing.user_signing"

    BACKUP_SECRET = "m.megolm_backup.v1"

    CROSS_SIGNING = [MASTER, SELF_SIGNING, USER_SIGNING].freeze

    SECRETS = [*CROSS_SIGNING, BACKUP_SECRET].freeze

    BACKUP_ALGORITHM = "m.megolm_backup.v1.curve25519-aes-sha2"

    PASSPHRASE_ITERATIONS = 500_000

    SALT_BYTES = 32

    BACKUP_VERSION = "key_backup_version"

    EXPORT_HEADER = "-----BEGIN MEGOLM SESSION DATA-----"

    EXPORT_FOOTER = "-----END MEGOLM SESSION DATA-----"

    EXPORT_ROUNDS = 500_000

    module_function

    def with_client
      credential = Models::Matrix::Credential.first

      unless credential&.usable?
        raise Error, "not signed in"
      end

      Session.open(credential) do |client, _credentials|
        yield client, credential
      end
    end

    def user_id
      Models::Matrix::Credential.first&.matrix_user_id.to_s
    end

    def own_identity
      Models::Matrix::UserIdentity.first(matrix_user_id: self.user_id, own: true)
    end

    def identity?
      !self.own_identity.nil?
    end

    def recovery?
      !Models::Matrix::AccountData.content_for(event_type: DEFAULT_KEY).to_h["key"].to_s.empty?
    end

    def passphrase?
      key_id = Models::Matrix::AccountData.content_for(event_type: DEFAULT_KEY).to_h["key"].to_s

      if key_id.empty?
        false
      else
        !Models::Matrix::AccountData
          .content_for(event_type: "m.secret_storage.key.#{key_id}").to_h["passphrase"].nil?
      end
    end

    def backup_version
      Models::Matrix::KV[BACKUP_VERSION]
    end

    def held_secrets
      Models::Matrix::SecretsInbox.select_map(:secret_name)
    end

    def missing_secrets
      SECRETS - self.held_secrets
    end

    def status
      {
        identity:  self.identity?,
        recovery:  self.recovery?,
        published: Device.published?,
        backup:    self.backup_version,
        missing:   self.missing_secrets,
        sessions:  Device.machine.sessions.size,
        key:       !self.backup_key.to_s.empty?,
      }
    end

    def prepare!
      Device.forget!
      Device.describe_storage!

      self.with_client do |client, _opened|
        Device.publish_keys!(client)

        unless Device.machine.identity.self_signing_key.nil?
          self.sign_own_device!(client)
        end
      end
    rescue StandardError => error
      Console.warn(self, "Could not publish this session's keys.", error: error)

      nil
    end

    def bootstrap_identity!(auth: nil)
      machine = Device.machine
      identity = machine.create_cross_signing_keys

      self.with_client do |client, _credential|
        client.cross_signing.upload_cross_signing_keys(
          master_key:       identity.master,
          self_signing_key: identity.self_signing,
          user_signing_key: identity.user_signing,
          auth:             auth,
        )

        self.sign_own_device!(client, machine)
      end

      self.remember_identity!(identity)
      self.hold_identity!(identity)
      self.write_secrets!

      identity.master_key
    end

    def sign_own_device!(client = nil, machine = Device.machine)
      signatures = machine.sign_own_device

      if signatures.nil?
        raise Error, "this session holds no self signing key, so it cannot sign itself"
      end

      payload = self.signed_device_keys(machine, signatures)

      if client.nil?
        answer = self.with_client{|opened, _credential| opened.cross_signing.upload_cross_signing_signatures(payload)}
      else
        answer = client.cross_signing.upload_cross_signing_signatures(payload)
      end

      unless answer.failures.empty?
        raise Error, "the homeserver refused the signature: #{answer.failures}"
      end

      answer
    end

    def signed_device_keys(machine, signatures)
      keys = machine.device_keys
      user_id = machine.user_id
      device_id = machine.device_id
      written = signatures[user_id] || signatures[user_id.to_sym] || {}
      added = written[device_id] || written[device_id.to_sym] || {}

      {
        user_id => {
          device_id => keys.merge(
            signatures: {user_id => self.stringified(keys[:signatures].to_h.values.first.to_h).merge(self.stringified(added))},
          ),
        },
      }
    end

    def stringified(value)
      value.to_h{|name, held| [name.to_s, held]}
    end

    def reset_identity!(auth: nil)
      Models::Matrix::SecretsInbox.where(secret_name: [MASTER, SELF_SIGNING, USER_SIGNING]).delete

      self.bootstrap_identity!(auth: auth)
    end

    def remember_identity!(identity)
      row = self.own_identity ||
        Models::Matrix::UserIdentity.new(matrix_user_id: self.user_id, own: true)

      row.set(
        master_key:       identity.master_key,
        self_signing_key: identity.self_signing_key,
        user_signing_key: identity.user_signing_key,
        verified:         true,
      )
      row.save_changes(validate: false)
    end

    def hold_identity!(identity)
      {
        MASTER => identity.private_master,
        SELF_SIGNING => identity.private_self_signing,
        USER_SIGNING => identity.private_user_signing,
      }.each do |name, secret|
        self.hold!(name, secret)
      end
    end

    def hold!(name, secret)
      unless secret.to_s.empty?
        row = Models::Matrix::SecretsInbox.first(secret_name: name) ||
          Models::Matrix::SecretsInbox.new(secret_name: name)

        row.set(secret: secret).save_changes(validate: false)

        Device.secrets.accept(name, secret)
      end
    end

    def enable_recovery!(passphrase = nil)
      key_id = SecureRandom.alphanumeric(24)

      if passphrase.to_s.empty?
        key = Async::Matrix::E2EE::SecretStorage::Key.generate
        description = key.description(name: "Recovery key")
      else
        salt = Async::Matrix::E2EE::SecretStorage::Key.encode(SecureRandom.bytes(SALT_BYTES))
        key = Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(
          passphrase, salt: salt, iterations: PASSPHRASE_ITERATIONS,
        )
        description = key.description(
          name:       "Recovery passphrase",
          passphrase: {
            algorithm:  Async::Matrix::E2EE::SecretStorage::PBKDF2,
            salt:       salt,
            iterations: PASSPHRASE_ITERATIONS,
          },
        )
      end

      RoomActions.set_global_account_data("m.secret_storage.key.#{key_id}", description)
      RoomActions.set_global_account_data(DEFAULT_KEY, {key: key_id})

      Device.secrets.describe(key_id, description)
      Device.secrets.opened(key)

      self.write_secrets!
      self.ensure_backup!

      key.to_s
    end

    def write_secrets!
      secrets = Models::Matrix::SecretsInbox.all.to_h{|row| [row.secret_name, row.secret]}

      Device.secrets.store(secrets).each do |name, content|
        RoomActions.set_global_account_data(name, content)
      end

      secrets.keys
    end

    def recover!(secret)
      key_id = Device.describe_storage!

      if key_id.empty?
        raise Error, "this account has no recovery set up"
      end

      key = self.key_for(secret, key_id)

      unless Device.secrets.opened(key)
        raise Error, "that passphrase or recovery key does not open the recovery"
      end

      opened = SECRETS.filter_map do |name|
        held = Device.secrets.load(name)

        unless held.to_s.empty?
          self.hold!(name, held)

          name
        end
      end

      self.accept_secrets!(opened)

      {opened: opened, missing: SECRETS - opened}
    end

    def key_for(secret, key_id)
      description = Device.symbolized(
        Models::Matrix::AccountData.content_for(event_type: "m.secret_storage.key.#{key_id}").to_h,
      )

      case description
      in {passphrase: {salt: String => salt, iterations: Integer => iterations, **rest}}
        Async::Matrix::E2EE::SecretStorage::Key.from_passphrase(
          secret, salt: salt, iterations: iterations, bits: rest.fetch(:bits, 256),
        )
      else
        self.from_representation(secret)
      end
    end

    def from_representation(secret)
      Async::Matrix::E2EE::SecretStorage::Key.from_bytes(
        Async::Matrix::KeyRepresentation.decode(secret.to_s.gsub(/\s+/, "")),
      )
    rescue Async::Matrix::InvalidKeyError
      raise Error, "that is not a recovery key"
    end

    def accept_secrets!(names)
      machine = Device.machine

      names.each do |name|
        case name
        in MASTER | SELF_SIGNING | USER_SIGNING
          machine.accept_cross_signing_secret(name, Device.secrets.held(name))
        in BACKUP_SECRET
          nil
        end
      end

      identity = machine.identity

      unless identity.master_key.nil?
        self.remember_identity!(identity)
      end
    end

    def reset_recovery!(passphrase = nil)
      SECRETS.each do |name|
        RoomActions.set_global_account_data(name, {})
      end

      self.enable_recovery!(passphrase)
    end

    def disable_recovery!
      key_id = Models::Matrix::AccountData.content_for(event_type: DEFAULT_KEY).to_h["key"].to_s

      unless key_id.empty?
        RoomActions.set_global_account_data("m.secret_storage.key.#{key_id}", {})
      end

      RoomActions.set_global_account_data(DEFAULT_KEY, {})

      SECRETS.each do |name|
        RoomActions.set_global_account_data(name, {})
      end
    end

    def ensure_backup!
      if self.backup_version.to_s.empty?
        self.create_backup!
      else
        self.backup_version
      end
    end

    def create_backup!
      backup = Async::Matrix::E2EE::Backup.generate

      version = self.with_client do |client, _credential|
        client.key_backup.post_room_keys_version(
          algorithm: BACKUP_ALGORITHM, auth_data: backup.auth_data,
        ).version
      end

      Models::Matrix::KV.set!(BACKUP_VERSION, version)
      self.hold!(BACKUP_SECRET, backup.private_key)
      self.write_secrets!

      version
    end

    def delete_backup!
      self.backup_version.tap do |version|
        unless version.to_s.empty?
          self.with_client do |client, _credential|
            client.key_backup.delete_room_keys_version(version)
          end

          Models::Matrix::KV.unset!(BACKUP_VERSION)
        end
      end
    end

    def back_up_keys!
      version = self.ensure_backup!
      private_key = self.backup_key

      if private_key.to_s.empty?
        raise Error, "this session does not hold the backup key"
      end

      backup = Async::Matrix::E2EE::Backup.from_private_key(private_key, version: version)
      machine = Device.machine
      rooms = {}

      machine.sessions.each do |session|
        exported = machine.export_for_backup(session)
        room = rooms[exported[:room_id]] ||= {sessions: {}}
        room[:sessions][exported[:session_id]] = backup.encrypt(exported)
      end

      unless rooms.empty?
        self.with_client do |client, _credential|
          client.key_backup.keys(version).put_room_keys(rooms)
        end
      end

      rooms.sum{|_, room| room[:sessions].size}
    end

    def backup_key
      Device.secrets.held(BACKUP_SECRET) ||
        Models::Matrix::SecretsInbox.first(secret_name: BACKUP_SECRET)&.secret
    end

    def restore_backup!
      version = self.backup_version
      private_key = self.backup_key

      if version.to_s.empty? || private_key.to_s.empty?
        raise Error, "this session cannot read the backup"
      end

      backup = Async::Matrix::E2EE::Backup.from_private_key(private_key, version: version)
      machine = Device.machine

      restored = self.with_client do |client, _credential|
        client.key_backup.keys(version).get_room_keys.rooms
      end

      count = 0

      restored.each do |room_id, room|
        (room[:sessions] || {}).each do |session_id, held|
          opened = backup.decrypt(held[:session_data])

          machine.import_inbound_session(
            room_id.to_s,
            session_id:  session_id.to_s,
            session_key: opened[:session_key],
            sender:      opened[:sender_key],
          )

          count += 1
        end
      end

      Device.persist!

      count
    end

    def export_keys(passphrase)
      machine = Device.machine

      sessions = machine.sessions.map do |session|
        exported = machine.export_for_backup(session)

        {
          "algorithm" => exported[:algorithm],
          "room_id" => exported[:room_id],
          "sender_key" => exported[:sender_key],
          "session_id" => exported[:session_id],
          "session_key" => exported[:session_key],
          "sender_claimed_keys" => exported[:sender_claimed_keys],
          "forwarding_curve25519_key_chain" => exported[:forwarding_curve25519_key_chain],
        }
      end

      self.sealed_export(MultiJson.dump(sessions), passphrase)
    end

    def sealed_export(plaintext, passphrase)
      salt = SecureRandom.bytes(16)
      iv = SecureRandom.bytes(16)
      aes, mac = self.export_keys_for(passphrase, salt)

      cipher = OpenSSL::Cipher.new("AES-256-CTR")
      cipher.encrypt
      cipher.key = aes
      cipher.iv = iv

      body = +"\x01".b
      body << salt
      body << iv
      body << [EXPORT_ROUNDS].pack("N")
      body << cipher.update(plaintext) + cipher.final
      body << OpenSSL::HMAC.digest("SHA256", mac, body)

      [EXPORT_HEADER, Base64.strict_encode64(body).scan(/.{1,64}/), EXPORT_FOOTER, ""].flatten.join("\n")
    end

    def import_keys(bytes, passphrase)
      body = Base64.decode64(
        bytes.to_s.gsub(EXPORT_HEADER, "").gsub(EXPORT_FOOTER, "").gsub(/\s+/, ""),
      )

      unless body.getbyte(0) == 1 && body.bytesize > 69
        raise Error, "that is not a room key export"
      end

      salt = body.byteslice(1, 16)
      iv = body.byteslice(17, 16)
      rounds = body.byteslice(33, 4).unpack1("N")
      ciphertext = body.byteslice(37, body.bytesize - 37 - 32)
      aes, mac = self.export_keys_for(passphrase, salt, rounds: rounds)

      unless OpenSSL.secure_compare(
        OpenSSL::HMAC.digest("SHA256", mac, body.byteslice(0, body.bytesize - 32)),
        body.byteslice(body.bytesize - 32, 32),
      )
        raise Error, "that passphrase does not open the export"
      end

      cipher = OpenSSL::Cipher.new("AES-256-CTR")
      cipher.decrypt
      cipher.key = aes
      cipher.iv = iv

      self.import_sessions!(MultiJson.load(cipher.update(ciphertext) + cipher.final))
    end

    def export_keys_for(passphrase, salt, rounds: EXPORT_ROUNDS)
      derived = OpenSSL::KDF.pbkdf2_hmac(
        passphrase.to_s, salt: salt, iterations: rounds, length: 64, hash: "SHA512",
      )

      [derived.byteslice(0, 32), derived.byteslice(32, 32)]
    end

    def import_sessions!(sessions)
      machine = Device.machine

      count = sessions.count do |session|
        machine.import_inbound_session(
          session["room_id"].to_s,
          session_id:  session["session_id"].to_s,
          session_key: session["session_key"],
          sender:      session["sender_key"],
        )

        true
      end

      Device.persist!

      count
    rescue RuntimeError, TypeError, NoMethodError
      raise Error, "that export is not room keys"
    end
  end
end
