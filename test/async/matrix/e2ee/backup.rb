# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/backup"
require "async/matrix/e2ee/machine"

describe Async::Matrix::E2EE::Backup do
  let(:backup) {subject.generate}

  let(:other) {subject.generate}

  # One session as {Machine#export_for_backup} answers it, which is what a backup is written from.
  let(:session) do
    {
      room_id: "!room:localhost",
      session_id: "session",
      algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
      session_key: "AgAAAAAwMTIzNDU2Nzg5",
      sender_key: "sender-curve25519-key",
      sender_claimed_keys: {ed25519: "sender-ed25519-key"},
      forwarding_curve25519_key_chain: ["someone-else"],
      shared_history: true,
      first_message_index: 3,
      forwarded_count: 1,
      is_verified: true,
    }
  end

  with ".generate" do
    it "holds both halves, so it can be read as well as written to" do
      expect(backup).to be(:private?)
      expect(backup.private_key).not.to be_nil
    end

    it "makes a different key each time" do
      expect(other.public_key).not.to be == backup.public_key
    end

    it "belongs to no backup on the server yet" do
      expect(backup.version).to be_nil
    end
  end

  with ".from_private_key" do
    it "is the same backup as the key it was given" do
      expect(subject.from_private_key(backup.private_key).public_key).to be == backup.public_key
    end

    it "reads a session the backup it came from wrote" do
      written = backup.encrypt(session)

      expect(subject.from_private_key(backup.private_key).decrypt(written[:session_data])).not.to be_nil
    end

    # The specification carries base64 unpadded, and the binding refuses padding rather than ignoring it.
    it "takes a key whose padding a client left on" do
      padded = "#{backup.private_key}=="

      expect(subject.from_private_key(padded).public_key).to be == backup.public_key
    end

    it "carries the version it was told" do
      expect(subject.from_private_key(backup.private_key, version: "7").version).to be == "7"
    end
  end

  with ".from_public_key" do
    let(:writing) {subject.from_public_key(backup.public_key, version: "7")}

    # This is what a device has when the backup is somebody else's to read: enough to add to it.
    it "holds only the half which writes" do
      expect(writing).not.to be(:private?)
      expect(writing.private_key).to be_nil
      expect(writing.public_key).to be == backup.public_key
    end

    it "writes a session the holder of the private half can read" do
      written = writing.encrypt(session)

      expect(backup.decrypt(written[:session_data])[:session_key]).to be == session[:session_key]
    end

    it "refuses to read anything at all" do
      written = writing.encrypt(session)

      expect{writing.decrypt(written[:session_data])}.to raise_exception(ArgumentError)
    end
  end

  with "#at" do
    it "is the same backup, known to be a particular one on the server" do
      known = backup.at("7")

      expect(known.version).to be == "7"
      expect(known.public_key).to be == backup.public_key
      expect(known.private_key).to be == backup.private_key
    end
  end

  with "#auth_data" do
    # This is what every other device checks before writing, and what a signature is made over.
    it "carries the public half and nothing else" do
      expect(backup.auth_data).to be == {public_key: backup.public_key}
    end
  end

  with "#encrypt" do
    let(:written) {backup.encrypt(session)}

    # The fields outside `session_data` are what the server breaks a tie with, so they travel in the clear.
    it "sends the fields the server decides a tie with in the clear" do
      expect(written[:first_message_index]).to be == 3
      expect(written[:forwarded_count]).to be == 1
      expect(written[:is_verified]).to be == true
    end

    it "sends the session itself as the three parts of the ciphertext" do
      expect(written[:session_data].keys.sort).to be == [:ciphertext, :ephemeral, :mac]
    end

    # The key material is the whole point: none of it may be readable by the server.
    it "sends nothing of the session outside the ciphertext" do
      expect(written.reject{|name, _| name == :session_data}.values.map(&:to_s)).not.to be(:include?, session[:session_key])
    end

    it "answers for a session which says none of what the server breaks a tie with" do
      written = backup.encrypt({session_key: session[:session_key], sender_key: session[:sender_key]})

      expect(written[:first_message_index]).to be == 0
      expect(written[:forwarded_count]).to be == 0
      expect(written[:is_verified]).to be == false
    end

    # An ephemeral key per message means the same session written twice looks nothing alike.
    it "writes different ciphertext each time" do
      expect(backup.encrypt(session)[:session_data][:ciphertext]).not.to be == written[:session_data][:ciphertext]
    end
  end

  with "#decrypt" do
    it "reads back the fields the specification names" do
      read = backup.decrypt(backup.encrypt(session)[:session_data])

      expect(read.keys.sort).to be == [:algorithm, :forwarding_curve25519_key_chain, :sender_claimed_keys, :sender_key, :session_key, :shared_history]
    end

    it "reads back what was written" do
      read = backup.decrypt(backup.encrypt(session)[:session_data])

      expect(read[:algorithm]).to be == Async::Matrix::E2EE::Machine::MEGOLM
      expect(read[:session_key]).to be == session[:session_key]
      expect(read[:sender_key]).to be == session[:sender_key]
      expect(read[:sender_claimed_keys]).to be == session[:sender_claimed_keys]
      expect(read[:forwarding_curve25519_key_chain]).to be == session[:forwarding_curve25519_key_chain]
      expect(read[:shared_history]).to be == true
    end

    it "reads a session which was written knowing less about it" do
      read = backup.decrypt(backup.encrypt({session_key: session[:session_key], sender_key: session[:sender_key]})[:session_data])

      expect(read[:algorithm]).to be == Async::Matrix::E2EE::Machine::MEGOLM
      expect(read[:forwarding_curve25519_key_chain]).to be == []
      expect(read[:sender_claimed_keys]).to be == {}
      expect(read[:shared_history]).to be == false
    end

    # Anybody can add to a backup, so a session which does not read is one written to another key.
    it "answers nothing for a session written to another key" do
      expect(backup.decrypt(other.encrypt(session)[:session_data])).to be_nil
    end

    # The code over the ciphertext authenticates nothing, which is libolm's bug and the specification's warning.
    it "answers nothing for a session whose parts were changed" do
      written = backup.encrypt(session)[:session_data]

      expect(backup.decrypt(written.merge(mac: other.encrypt(session)[:session_data][:mac]))).to be_nil
    end

    it "reads a session whose padding a client left on" do
      written = backup.encrypt(session)[:session_data]
      padded = written.transform_values{|part| "#{part}#{"=" * (-part.bytesize % 4)}"}

      expect(backup.decrypt(padded)[:session_key]).to be == session[:session_key]
    end
  end

  with "ALGORITHM" do
    it "is the only backup algorithm the specification defines" do
      expect(subject::ALGORITHM).to be == "m.megolm_backup.v1.curve25519-aes-sha2"
    end
  end

  with ".unpadded" do
    it "takes padding off" do
      expect(subject.unpadded("aGVsbG8=")).to be == "aGVsbG8"
    end

    it "leaves what carries none alone" do
      expect(subject.unpadded("aGVsbG8")).to be == "aGVsbG8"
    end
  end
end
