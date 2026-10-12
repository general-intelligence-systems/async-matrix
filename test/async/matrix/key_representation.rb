# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/key_representation"

describe Async::Matrix::KeyRepresentation do
  # The key `matrix-rust-sdk` reads in `base58_parsing`, whose bytes it names.
  KEY = [
    159, 189, 70, 187, 52, 81, 113, 198, 246, 2, 44, 154, 37, 213, 104, 27, 165, 78, 236,
    106, 108, 73, 83, 243, 173, 192, 185, 110, 157, 145, 173, 163,
  ].pack("C*").freeze

  # The same key as that implementation writes it, in groups of four.
  REPRESENTED = "EsTp RvZT njck 8Yrh RAtw XLS8 4Nr2 r9S9 LGAW DaEx VAPB vLRK"

  with ".encode" do
    it "writes the key another implementation wrote" do
      expect(subject.encode(KEY)).to be == REPRESENTED
    end

    it "writes the characters in groups of four" do
      expect(subject.encode(KEY).split(" ").map(&:length).uniq).to be == [4]
    end

    # Base58 drops a leading zero, so the specification's own encoding carries it as a `1`.
    it "writes a key which begins with zero bytes" do
      expect(subject.decode(subject.encode("\u0000\u0000ab"))).to be == "\u0000\u0000ab".b
    end

    it "writes a key of any length, because the appendices give it no length" do
      [1, 16, 32, 64].each do |length|
        expect(subject.decode(subject.encode("k" * length))).to be == "k" * length
      end
    end
  end

  with ".decode" do
    it "reads the key another implementation wrote" do
      expect(subject.decode(REPRESENTED)).to be == KEY
    end

    # The appendices say whitespace is insignificant in what a person typed.
    it "disregards whitespace, however much of it there is" do
      expect(subject.decode("EsT           pRvZTnjck8    YrhRAtw XLS84Nr2r9S9LGAWDaExVAPBvLRK   ")).to be == KEY
    end

    it "reads a key with no whitespace at all" do
      expect(subject.decode(REPRESENTED.delete(" "))).to be == KEY
    end

    it "takes the length the caller knows the key to be" do
      expect(subject.decode(REPRESENTED, length: 32)).to be == KEY
    end
  end

  # The four ways `matrix-rust-sdk` refuses one, which are the four things there are to check.
  with "a representation which is wrong" do
    it "refuses a parity byte which does not match the key" do
      expect do
        subject.decode("EsTpRvZTnjck8YrhRAtwXLS84Nr2r9S9LGAWDaExVAPBvLRk", length: 32)
      end.to raise_exception(Async::Matrix::InvalidKeyError, message: be =~ /parity/)
    end

    it "refuses a header which is not the two bytes the appendices give" do
      expect do
        subject.decode("AATpRvZTnjck8YrhRAtwXLS84Nr2r9S9LGAWDaExVAPBvLRk", length: 32)
      end.to raise_exception(Async::Matrix::InvalidKeyError, message: be =~ /begins with 8b01/)
    end

    it "refuses a key which is not the length the caller wanted" do
      expect do
        subject.decode("AATpRvZTnjck8YrhRAtwXLS84Nr2r9S9", length: 32)
      end.to raise_exception(Async::Matrix::InvalidKeyError, message: be =~ /21 bytes/)
    end

    # Zero, capital O, capital I and lower case l are the characters the alphabet leaves out.
    it "refuses a character the alphabet does not hold" do
      expect do
        subject.decode("AATpRvZTnjck8YrhRAtwXLS84Nr0OIl", length: 32)
      end.to raise_exception(Async::Matrix::InvalidKeyError, message: be =~ /base58/)
    end

    it "refuses a representation with no room for a key in it" do
      expect{subject.decode("111")}.to raise_exception(Async::Matrix::InvalidKeyError)
    end
  end

  with ".parity" do
    # Every byte exclusive ored together, the header included, which is what the appendices say.
    it "folds the bytes together" do
      expect(subject.parity("\x8B\x01".b)).to be == 0x8A
      expect(subject.parity("\x8B\x01\x8A".b)).to be == 0x00
    end
  end

  with ".base58" do
    # The alphabet is the one bitcoin addresses use, so its own test values hold here.
    it "writes bytes as the bitcoin alphabet" do
      expect(subject.base58("")).to be == ""
      expect(subject.base58("\x00".b)).to be == "1"
      expect(subject.base58("hello world")).to be == "StV1DL6CwTryKyV"
    end

    it "reads back what it wrote" do
      ["", "\x00".b, "hello world", "\xff\xff\xff".b].each do |bytes|
        expect(subject.bytes(subject.base58(bytes))).to be == bytes
      end
    end
  end
end
