# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/secret_storage"
require "async/matrix/key_representation"

describe Async::Matrix::E2EE::SecretStorage::Key do
  let(:key) {subject.generate}

  let(:other) {subject.generate}

  with ".generate" do
    it "makes a key of the length the specification asks for" do
      expect(key.bytes.bytesize).to be == Async::Matrix::E2EE::SecretStorage::BYTES
    end

    it "makes a different key each time" do
      expect(key.bytes).not.to be == other.bytes
    end
  end

  with ".from_bytes" do
    it "is the same key as the bytes it was given" do
      expect(subject.from_bytes(key.bytes).bytes).to be == key.bytes
    end

    # A key arrives as whatever encoding read it, and the cipher is given bytes.
    it "holds the bytes as bytes, whatever encoding they arrived in" do
      expect(subject.from_bytes(key.bytes.dup.force_encoding(Encoding::UTF_8)).bytes.encoding).to be == Encoding::BINARY
    end
  end

  with ".from_passphrase" do
    # The derivation is what makes a passphrase worth as much as the key itself, so it has to be the same every time.
    it "arrives at the same key for the same passphrase and description" do
      first = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000)
      again = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000)

      expect(again.bytes).to be == first.bytes
    end

    it "arrives at a different key for a different passphrase" do
      first = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000)
      other = subject.from_passphrase("battery staple", salt: "salt", iterations: 1000)

      expect(other.bytes).not.to be == first.bytes
    end

    it "arrives at a different key for a different salt" do
      first = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000)
      other = subject.from_passphrase("correct horse", salt: "pepper", iterations: 1000)

      expect(other.bytes).not.to be == first.bytes
    end

    it "derives the length the description asks for" do
      derived = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000, bits: 128)

      expect(derived.bytes.bytesize).to be == 16
    end
  end

  with "#encrypt" do
    it "writes the counter, the ciphertext and the code over it" do
      expect(key.encrypt("m.secret", "hello").keys.sort).to be == [:ciphertext, :iv, :mac]
    end

    it "writes each part as unpadded base64" do
      key.encrypt("m.secret", "hello").each_value do |part|
        expect(part).not.to be(:include?, "=")
      end
    end

    # The counter is random, so the same secret under the same key is different ciphertext each time.
    it "writes a different counter each time" do
      expect(key.encrypt("m.secret", "hello")[:iv]).not.to be == key.encrypt("m.secret", "hello")[:iv]
    end

    # The specification asks for the top bit to be cleared, because implementations disagree about where the counter wraps.
    it "writes a counter with the top bit cleared" do
      iv = subject.decode(key.encrypt("m.secret", "hello")[:iv])

      expect(iv.bytesize).to be == 16
      expect(iv.getbyte(8) & 0x80).to be == 0
    end
  end

  with "#decrypt" do
    it "reads back what this key wrote" do
      expect(key.decrypt("m.secret", key.encrypt("m.secret", "hello"))).to be == "hello"
    end

    it "reads back a secret of no length at all" do
      expect(key.decrypt("m.secret", key.encrypt("m.secret", ""))).to be == ""
    end

    # The name is part of the derivation, so one secret's key cannot read another's.
    it "refuses a secret written under another name" do
      expect(key.decrypt("m.other", key.encrypt("m.secret", "hello"))).to be_nil
    end

    it "refuses a secret another key wrote" do
      expect(other.decrypt("m.secret", key.encrypt("m.secret", "hello"))).to be_nil
    end

    # The code is over the ciphertext, so a changed ciphertext is caught rather than decrypted to rubbish.
    it "refuses a ciphertext which was changed" do
      written = key.encrypt("m.secret", "hello")
      tampered = written.merge(ciphertext: subject.encode(subject.decode(written[:ciphertext]).succ))

      expect(key.decrypt("m.secret", tampered)).to be_nil
    end

    # Some clients write padded base64, and a secret they wrote still has to read.
    it "reads a secret whose parts carry padding" do
      written = key.encrypt("m.secret", "hello")
      padded = written.transform_values{|part| "#{part}#{"=" * (-part.bytesize % 4)}"}

      expect(key.decrypt("m.secret", padded)).to be == "hello"
    end
  end

  with "#correct?" do
    # This is what tells a wrong passphrase from a right one before anything is decrypted with it.
    it "says a key is the one its own description was written by" do
      description = key.description

      expect(key.correct?(iv: description[:iv], mac: description[:mac])).to be == true
    end

    it "says another key is not" do
      description = key.description

      expect(other.correct?(iv: description[:iv], mac: description[:mac])).to be == false
    end

    it "says a passphrase which derives the key is the right one" do
      passphrase = {algorithm: Async::Matrix::E2EE::SecretStorage::PBKDF2, salt: "salt", iterations: 1000}
      derived = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000)
      description = derived.description(passphrase: passphrase)

      again = subject.from_passphrase("correct horse", salt: "salt", iterations: 1000)
      wrong = subject.from_passphrase("battery staple", salt: "salt", iterations: 1000)

      expect(again.correct?(iv: description[:iv], mac: description[:mac])).to be == true
      expect(wrong.correct?(iv: description[:iv], mac: description[:mac])).to be == false
    end
  end

  with "#description" do
    it "names the only algorithm the specification defines" do
      expect(key.description[:algorithm]).to be == Async::Matrix::E2EE::SecretStorage::ALGORITHM
    end

    # The description goes to the server, so anything of the key itself in it would defeat the point.
    it "carries no key material" do
      expect(key.description(name: "Default key").values_at(:iv, :mac)).not.to be(:include?, key.bytes)
      expect(key.description.keys).not.to be(:include?, :key)
    end

    it "leaves out what it was not given" do
      expect(key.description.keys.sort).to be == [:algorithm, :iv, :mac]
    end

    it "carries the name and the derivation where there is one" do
      passphrase = {algorithm: Async::Matrix::E2EE::SecretStorage::PBKDF2, salt: "salt", iterations: 1000}
      description = key.description(name: "Default key", passphrase: passphrase)

      expect(description[:name]).to be == "Default key"
      expect(description[:passphrase]).to be == passphrase
    end

    # A fresh counter each time means two descriptions of one key look nothing alike, and both check out.
    it "writes a description which checks out however many are made" do
      first = key.description
      again = key.description

      expect(again[:mac]).not.to be == first[:mac]
      expect(key.correct?(iv: first[:iv], mac: first[:mac])).to be == true
      expect(key.correct?(iv: again[:iv], mac: again[:mac])).to be == true
    end
  end

  with "#to_s" do
    # The only place a key is shown is to the person who has to write it down.
    it "shows the key in the representation the appendices describe" do
      expect(Async::Matrix::KeyRepresentation.decode(key.to_s)).to be == key.bytes
    end
  end

  with ".encode" do
    it "writes unpadded base64" do
      expect(subject.encode("hello")).to be == "aGVsbG8"
    end
  end

  with ".decode" do
    it "reads what it wrote" do
      expect(subject.decode(subject.encode("hello"))).to be == "hello"
    end

    it "reads padded base64 too, because some clients write it" do
      expect(subject.decode("aGVsbG8=")).to be == "hello"
    end
  end
end
