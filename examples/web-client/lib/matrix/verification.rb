# frozen_string_literal: true

require "async/matrix"
require "async/matrix/e2ee"
require "base64"
require "digest"
require "openssl"
require "securerandom"
require "vodozemac"

require_relative "room_actions"
require_relative "device"
require_relative "session"

module Matrix
  module Verification
    class Error < RoomActions::Error
    end

    SAS = "m.sas.v1"

    SHOW_QR = "m.qr_code.show.v1"

    SCAN_QR = "m.qr_code.scan.v1"

    RECIPROCATE = "m.reciprocate.v1"

    METHODS = [SAS, SHOW_QR, SCAN_QR, RECIPROCATE].freeze

    QR_PREFIX = "MATRIX"

    QR_VERSION = 2

    QR_VERIFY_OTHER = 0

    QR_SELF_TRUSTED = 1

    QR_SELF_UNTRUSTED = 2

    QR_SECRET_BYTES = 16

    KEY_AGREEMENT = "curve25519-hkdf-sha256"

    HASH = "sha256"

    MAC = "hkdf-hmac-sha256.v2"

    STRINGS = %w[emoji decimal].freeze

    REQUEST = "m.key.verification.request"

    READY = "m.key.verification.ready"

    START = "m.key.verification.start"

    ACCEPT = "m.key.verification.accept"

    KEY = "m.key.verification.key"

    MAC_EVENT = "m.key.verification.mac"

    DONE = "m.key.verification.done"

    CANCEL = "m.key.verification.cancel"

    TIMEOUT_MS = 600_000

    EMOJI = [
      ["🐶", "Dog"], ["🐱", "Cat"], ["🦁", "Lion"], ["🐎", "Horse"],
      ["🦄", "Unicorn"], ["🐷", "Pig"], ["🐘", "Elephant"], ["🐰", "Rabbit"],
      ["🐼", "Panda"], ["🐓", "Rooster"], ["🐧", "Penguin"], ["🐢", "Turtle"],
      ["🐟", "Fish"], ["🐙", "Octopus"], ["🦋", "Butterfly"], ["🌷", "Flower"],
      ["🌳", "Tree"], ["🌵", "Cactus"], ["🍄", "Mushroom"], ["🌏", "Globe"],
      ["🌙", "Moon"], ["☁️", "Cloud"], ["🔥", "Fire"], ["🍌", "Banana"],
      ["🍎", "Apple"], ["🍓", "Strawberry"], ["🌽", "Corn"], ["🍕", "Pizza"],
      ["🎂", "Cake"], ["❤️", "Heart"], ["🙂", "Smiley"], ["🤖", "Robot"],
      ["🎩", "Hat"], ["👓", "Glasses"], ["🔧", "Spanner"], ["🎅", "Santa"],
      ["👍", "Thumbs up"], ["☂️", "Umbrella"], ["⌛", "Hourglass"], ["⏰", "Clock"],
      ["🎁", "Gift"], ["💡", "Light bulb"], ["📕", "Book"], ["✏️", "Pencil"],
      ["📎", "Paperclip"], ["✂️", "Scissors"], ["🔒", "Lock"], ["🔑", "Key"],
      ["🔨", "Hammer"], ["☎️", "Telephone"], ["🏁", "Flag"], ["🚂", "Train"],
      ["🚲", "Bicycle"], ["✈️", "Aeroplane"], ["🚀", "Rocket"], ["🏆", "Trophy"],
      ["⚽", "Ball"], ["🎸", "Guitar"], ["🎺", "Trumpet"], ["🔔", "Bell"],
      ["⚓", "Anchor"], ["🎧", "Headphones"], ["📁", "Folder"], ["📌", "Pin"],
    ].freeze

    CODES = {
      "user" => "the other side said no",
      "timeout" => "it took too long",
      "accepted" => "another session answered it",
      "m.mismatched_sas" => "the emoji did not match",
      "m.key_mismatch" => "the keys did not match",
      "m.user_mismatch" => "that is not who it should be",
      "m.unknown_method" => "neither side offered a method both can do",
      "m.invalid_message" => "something arrived which makes no sense",
    }.freeze

    LIVE = {}

    LOCK = Mutex.new

    module_function

    def live(flow_id)
      LOCK.synchronize{LIVE[flow_id]}
    end

    def hold(flow_id, **fields)
      LOCK.synchronize{(LIVE[flow_id] ||= {}).merge!(fields)}
    end

    def drop(flow_id)
      LOCK.synchronize{LIVE.delete(flow_id)}
    end

    def flow!(flow_id)
      Models::Matrix::VerificationFlow.first(flow_id: flow_id) ||
        raise(Error, "no such verification")
    end

    def own_user_id
      Models::Matrix::Credential.first&.matrix_user_id.to_s
    end

    def own_device_id
      Models::Matrix::Credential.first&.device_id.to_s
    end

    def send!(type, user_id, device_ids, content)
      messages = {user_id => device_ids.to_h{|device_id| [device_id, content]}}

      Crypto.with_client do |client, _credential|
        client.to_device.send_to_device(type, messages)
      end
    end

    def targets(flow)
      case flow.other_device_id
      in nil
        ["*"]
      in String => device_id
        [device_id]
      end
    end

    def request!(user_id, device_ids = nil)
      flow_id = SecureRandom.alphanumeric(32)
      devices = device_ids || self.devices_of(user_id)

      if devices.empty?
        raise Error, "that user has no sessions to verify"
      end

      self.send!(REQUEST, user_id, devices, {
        from_device: self.own_device_id,
        transaction_id: flow_id,
        methods: METHODS,
        timestamp: (Time.now.to_f * 1000).to_i,
      })

      Models::Matrix::VerificationFlow.create(
        flow_id: flow_id,
        other_user_id: user_id,
        other_device_id: (devices.one? ? devices.first : nil),
        own: user_id == self.own_user_id,
        started_by_us: true,
        state: Models::Matrix::VerificationFlow::REQUESTED,
        methods_offered: METHODS,
      )
    end

    def devices_of(user_id)
      Models::Matrix::Device
        .where(matrix_user_id: user_id)
        .exclude(device_id: self.own_device_id)
        .select_map(:device_id)
    end

    def accept_request!(flow_id)
      flow = self.flow!(flow_id)

      self.send!(READY, flow.other_user_id, self.targets(flow), {
        from_device: self.own_device_id,
        transaction_id: flow_id,
        methods: METHODS,
      })

      flow.set(state: Models::Matrix::VerificationFlow::READY).save_changes(validate: false)
    end

    def start!(flow_id)
      flow = self.flow!(flow_id)

      content = {
        from_device: self.own_device_id,
        transaction_id: flow_id,
        method: SAS,
        key_agreement_protocols: [KEY_AGREEMENT],
        hashes: [HASH],
        message_authentication_codes: [MAC],
        short_authentication_string: STRINGS,
      }

      self.hold(flow_id, start: content, sas: Vodozemac::Sas.new)
      self.send!(START, flow.other_user_id, self.targets(flow), content)

      flow.set(
        state: Models::Matrix::VerificationFlow::STARTED,
        verification_method: SAS,
        key_agreement_protocol: KEY_AGREEMENT,
        hash_method: HASH,
        message_authentication_code: MAC,
      ).save_changes(validate: false)
    end

    def accept_start!(flow_id, content)
      flow = self.flow!(flow_id)
      sas = Vodozemac::Sas.new

      unless content[:key_agreement_protocols].to_a.include?(KEY_AGREEMENT) &&
          content[:message_authentication_codes].to_a.include?(MAC)
        self.cancel!(flow_id, code: "m.unknown_method")

        raise Error, "that session offered nothing this one can do"
      end

      commitment = Async::Matrix::E2EE::SecretStorage::Key.encode(
        Digest::SHA256.digest(
          sas.public_key + Async::Matrix::E2EE::CanonicalJSON.dump(content),
        ),
      )

      self.hold(flow_id, start: content, sas: sas, started_by_them: true)

      self.send!(ACCEPT, flow.other_user_id, self.targets(flow), {
        transaction_id: flow_id,
        key_agreement_protocol: KEY_AGREEMENT,
        hash: HASH,
        message_authentication_code: MAC,
        short_authentication_string: STRINGS,
        commitment: commitment,
      })

      flow.set(
        state: Models::Matrix::VerificationFlow::ACCEPTED,
        verification_method: SAS,
        key_agreement_protocol: KEY_AGREEMENT,
        hash_method: HASH,
        message_authentication_code: MAC,
        commitment: commitment,
        other_device_id: content[:from_device] || flow.other_device_id,
      ).save_changes(validate: false)

      self.send_key!(flow_id)
    end

    def accepted!(flow_id, content)
      flow = self.flow!(flow_id)

      flow.set(
        key_agreement_protocol: content[:key_agreement_protocol],
        hash_method: content[:hash_method],
        message_authentication_code: content[:message_authentication_code],
        commitment: content[:commitment],
        state: Models::Matrix::VerificationFlow::ACCEPTED,
      ).save_changes(validate: false)

      self.send_key!(flow_id)
    end

    def send_key!(flow_id)
      flow = self.flow!(flow_id)
      held = self.live(flow_id) || raise(Error, "this session is not holding that verification")

      self.send!(KEY, flow.other_user_id, self.targets(flow), {
        transaction_id: flow_id,
        key: held[:sas].public_key,
      })

      self.establish!(flow_id)
    end

    def receive_key!(flow_id, their_key)
      self.flow!(flow_id).set(their_key: their_key).save_changes(validate: false)
      self.hold(flow_id, their_key: their_key)

      self.establish!(flow_id)
    end

    def establish!(flow_id)
      flow = self.flow!(flow_id)
      held = self.live(flow_id)

      if held.nil? || held[:their_key].to_s.empty? || held[:established]
        nil
      else
        established = held[:sas].diffie_hellman(held[:their_key])

        self.hold(flow_id, established: established)

        info = self.sas_info(flow, held)

        flow.set(
          state: Models::Matrix::VerificationFlow::KEYED,
          emoji: established.emoji_indices(info).map{|index| EMOJI[index]},
          decimals: established.decimals(info),
        ).save_changes(validate: false)
      end
    end

    def sas_info(flow, held)
      ours = [self.own_user_id, self.own_device_id, held[:sas].public_key]
      theirs = [flow.other_user_id, flow.other_device_id.to_s, held[:their_key]]

      if held[:started_by_them]
        first, second = theirs, ours
      else
        first, second = ours, theirs
      end

      "MATRIX_KEY_VERIFICATION_SAS|#{first.join("|")}|#{second.join("|")}|#{flow.flow_id}"
    end

    def confirm!(flow_id)
      flow = self.flow!(flow_id)
      held = self.live(flow_id) || raise(Error, "this session is not holding that verification")
      established = held[:established] || raise(Error, "that verification has no shared secret yet")

      keys = self.keys_to_mac
      base = self.mac_info(flow)

      mac = keys.to_h do |name, key|
        [name, established.calculate_mac(key, "#{base}#{name}")]
      end

      self.send!(MAC_EVENT, flow.other_user_id, self.targets(flow), {
        transaction_id: flow_id,
        mac: mac,
        keys: established.calculate_mac(keys.keys.sort.join(","), "#{base}KEY_IDS"),
      })

      self.send!(DONE, flow.other_user_id, self.targets(flow), {transaction_id: flow_id})

      flow.set(state: Models::Matrix::VerificationFlow::CONFIRMED).save_changes(validate: false)
      self.settle!(flow_id)
    end

    def keys_to_mac
      master = Crypto.own_identity&.master_key

      {"ed25519:#{self.own_device_id}" => Device.fingerprint}.tap do |keys|
        unless master.to_s.empty?
          keys["ed25519:#{master}"] = master
        end
      end
    end

    def mac_info(flow, ours: true)
      if ours
        from, to = [self.own_user_id, self.own_device_id], [flow.other_user_id, flow.other_device_id.to_s]
      else
        from, to = [flow.other_user_id, flow.other_device_id.to_s], [self.own_user_id, self.own_device_id]
      end

      "MATRIX_KEY_VERIFICATION_MAC#{from[0]}#{from[1]}#{to[0]}#{to[1]}#{flow.flow_id}"
    end

    def receive_mac!(flow_id, content)
      flow = self.flow!(flow_id)
      held = self.live(flow_id)
      established = held && held[:established]

      if established.nil?
        self.cancel!(flow_id, code: "m.invalid_message")
      else
        base = self.mac_info(flow, ours: false)
        claimed = (content[:mac] || {}).to_h{|name, value| [name.to_s, value]}

        unless self.consistent?(established, claimed, content[:keys].to_s, base)
          self.cancel!(flow_id, code: "m.key_mismatch")

          raise Error, "the keys that session sent are not the ones it signed"
        end

        flow.set(their_keys: claimed).save_changes(validate: false)
        self.settle!(flow_id)
      end
    end

    def consistent?(established, claimed, over, base)
      established.verify_mac(claimed.keys.sort.join(","), "#{base}KEY_IDS", over) &&
        claimed.all? do |name, value|
          established.verify_mac(name.split(":", 2).last, "#{base}#{name}", value)
        end
    rescue StandardError
      false
    end

    def done!(flow_id)
      self.flow!(flow_id)
      self.settle!(flow_id)
    end

    def settle!(flow_id)
      self.flow!(flow_id).tap do |flow|
        if flow.state == Models::Matrix::VerificationFlow::CONFIRMED && !flow.their_keys.to_h.empty?
          self.trust!(flow)

          flow.set(state: Models::Matrix::VerificationFlow::DONE).save_changes(validate: false)
          self.drop(flow_id)
        end
      end
    end

    def trust!(flow)
      Models::Matrix::Device
        .where(matrix_user_id: flow.other_user_id, device_id: flow.other_device_id)
        .update(trust_state: Models::Matrix::Device::VERIFIED)

      master = flow.their_keys.to_h.keys.map{|name| name.split(":", 2).last}
      signatures = Device.machine.sign_verified(master)

      unless signatures.empty?
        Crypto.with_client do |client, _credential|
          signatures.each do |signature|
            client.cross_signing.upload_cross_signing_signatures(signature)
          end
        end
      end

      identity = Models::Matrix::UserIdentity.first(matrix_user_id: flow.other_user_id)

      unless identity.nil?
        identity.set(verified: true).save_changes(validate: false)
      end
    end

    def cancel!(flow_id, code: "user", reason: nil)
      Models::Matrix::VerificationFlow.first(flow_id: flow_id).tap do |flow|
        unless flow.nil?
          self.send!(CANCEL, flow.other_user_id, self.targets(flow), {
            transaction_id: flow_id,
            code: code,
            reason: reason || CODES.fetch(code, code),
          })

          self.cancelled!(flow_id, code: code, reason: reason)
        end
      end
    end

    def cancelled!(flow_id, code: "user", reason: nil)
      self.drop(flow_id)

      Models::Matrix::VerificationFlow.first(flow_id: flow_id).tap do |flow|
        unless flow.nil?
          flow.set(
            state: Models::Matrix::VerificationFlow::CANCELLED,
            cancel_code: code,
            cancel_reason: reason || CODES.fetch(code.to_s, code.to_s),
          ).save_changes(validate: false)
        end
      end
    end

    def requested!(flow_id, user_id, content)
      existing = Models::Matrix::VerificationFlow.first(flow_id: flow_id) ||
        Models::Matrix::VerificationFlow.new(flow_id: flow_id)

      existing.tap do |row|
        row.set(
          other_user_id: user_id,
          other_device_id: content[:from_device],
          own: user_id == self.own_user_id,
          started_by_us: false,
          state: Models::Matrix::VerificationFlow::REQUESTED,
          methods_offered: content[:methods].to_a.map(&:to_s),
        ).save_changes(validate: false)
      end
    end

    def ready!(flow_id, content)
      Models::Matrix::VerificationFlow.first(flow_id: flow_id).tap do |flow|
        unless flow.nil?
          flow.set(
            state: Models::Matrix::VerificationFlow::READY,
            other_device_id: content[:from_device] || flow.other_device_id,
            methods_offered: content[:methods].to_a.map(&:to_s),
          ).save_changes(validate: false)
        end
      end
    end

    def shared?(flow)
      flow.methods_offered.to_a.include?(SAS)
    end

    def emoji(flow)
      flow.emoji.to_a.map{|symbol, name| {symbol: symbol, name: name}}
    end

    def qr_mode(flow)
      master = Crypto.own_identity&.master_key

      if flow.other_user_id != self.own_user_id
        QR_VERIFY_OTHER
      elsif master.to_s.empty?
        QR_SELF_UNTRUSTED
      else
        QR_SELF_TRUSTED
      end
    end

    def qr_keys(flow, mode)
      master = Crypto.own_identity&.master_key.to_s
      theirs = Models::Matrix::UserIdentity.first(matrix_user_id: flow.other_user_id)&.master_key.to_s
      device = Models::Matrix::Device
        .first(matrix_user_id: flow.other_user_id, device_id: flow.other_device_id)&.ed25519.to_s

      case mode
      in QR_VERIFY_OTHER
        [master, theirs]
      in QR_SELF_TRUSTED
        [master, device]
      in QR_SELF_UNTRUSTED
        [Device.fingerprint, theirs]
      end
    end

    def qr_payload(flow)
      mode = self.qr_mode(flow)
      first, second = self.qr_keys(flow, mode)

      if first.empty? || second.empty?
        nil
      else
        secret = SecureRandom.bytes(QR_SECRET_BYTES)

        self.hold(flow.flow_id, qr_secret: secret)

        body = +QR_PREFIX.b
        body << QR_VERSION.chr
        body << mode.chr
        body << [flow.flow_id.bytesize].pack("n")
        body << flow.flow_id.b
        body << self.qr_bytes(first)
        body << self.qr_bytes(second)
        body << secret

        Base64.urlsafe_encode64(body, padding: false)
      end
    end

    def qr_bytes(key)
      Async::Matrix::E2EE::SecretStorage::Key.decode(key).byteslice(0, 32).to_s.ljust(32, "\x00")
    end

    def qr_read(payload)
      body = Base64.urlsafe_decode64(payload.to_s)

      unless body.byteslice(0, 6) == QR_PREFIX && body.getbyte(6) == QR_VERSION
        raise Error, "that is not a Matrix verification code"
      end

      length = body.byteslice(8, 2).unpack1("n")

      {
        mode: body.getbyte(7),
        flow_id: body.byteslice(10, length),
        first: Async::Matrix::E2EE::SecretStorage::Key.encode(body.byteslice(10 + length, 32)),
        second: Async::Matrix::E2EE::SecretStorage::Key.encode(body.byteslice(42 + length, 32)),
        secret: body.byteslice(74 + length, body.bytesize - 74 - length),
      }
    rescue ArgumentError
      raise Error, "that code did not read"
    end

    def scanned!(flow_id, payload)
      read = self.qr_read(payload)
      flow = self.flow!(flow_id)

      unless read[:flow_id] == flow_id
        raise Error, "that code belongs to a different verification"
      end

      self.hold(flow_id, qr_secret: read[:secret], their_qr: read)

      self.send!(START, flow.other_user_id, self.targets(flow), {
        from_device: self.own_device_id,
        transaction_id: flow_id,
        method: RECIPROCATE,
        secret: Base64.urlsafe_encode64(read[:secret], padding: false),
      })

      flow.set(
        state: Models::Matrix::VerificationFlow::STARTED,
        verification_method: RECIPROCATE,
      ).save_changes(validate: false)
    end

    def reciprocated!(flow_id, content)
      flow = self.flow!(flow_id)
      held = self.live(flow_id)
      ours = held && held[:qr_secret]
      theirs = Base64.urlsafe_decode64(content[:secret].to_s)

      if ours.nil? || !OpenSSL.secure_compare(ours, theirs)
        self.cancel!(flow_id, code: "m.key_mismatch")

        raise Error, "that session did not scan this code"
      end

      flow.set(
        state: Models::Matrix::VerificationFlow::CONFIRMED,
        verification_method: RECIPROCATE,
        other_device_id: content[:from_device] || flow.other_device_id,
      ).save_changes(validate: false)
    end

    def confirm_qr!(flow_id)
      flow = self.flow!(flow_id)
      read = (self.live(flow_id) || {})[:their_qr]

      unless read.nil?
        flow.set(their_keys: {"ed25519:#{read[:first]}" => read[:first]}).save_changes(validate: false)
      end

      self.send!(DONE, flow.other_user_id, self.targets(flow), {transaction_id: flow_id})

      flow.set(state: Models::Matrix::VerificationFlow::CONFIRMED).save_changes(validate: false)
      self.settle!(flow_id)
    end

    def offered(flow)
      flow.methods_offered.to_a & [SAS, SHOW_QR, SCAN_QR]
    end

    def qr?(flow)
      self.offered(flow).include?(SHOW_QR) || self.offered(flow).include?(SCAN_QR)
    end
  end
end
