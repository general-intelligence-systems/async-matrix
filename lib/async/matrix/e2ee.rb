# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

# Loads the native vodozemac binding (ext/async_matrix_e2ee) and namespaces the
# Olm/Megolm primitives under Async::Matrix::E2EE.
#
# The native classes (Account, Session, GroupSession, InboundGroupSession) and
# the module function verify_signature are defined by the Rust #[magnus::init].
# This file only locates and requires the compiled object.
#
#   account = Async::Matrix::E2EE::Account.new
#   account.curve25519_key            # => base64 string
#   group = Async::Matrix::E2EE::GroupSession.new
#   msg   = group.encrypt("hello")    # => base64 megolm message
#   inbound = Async::Matrix::E2EE::InboundGroupSession.new(group.session_key)
#   inbound.decrypt(msg)              # => ["hello", 0]

module Async
  module Matrix
    module E2EE
    end
  end
end

# rake-compiler installs the shared object alongside this file.
require_relative "async_matrix_e2ee"

test do
  describe "Async::Matrix::E2EE" do
    it "exposes account identity keys as base64" do
      account = Async::Matrix::E2EE::Account.new
      account.curve25519_key.should.be.kind_of String
      account.ed25519_key.should.be.kind_of String
      account.curve25519_key.length.should.be > 0
    end

    it "round-trips a megolm group message" do
      group   = Async::Matrix::E2EE::GroupSession.new
      inbound = Async::Matrix::E2EE::InboundGroupSession.new(group.session_key)

      message = group.encrypt("hello world")
      plaintext, index = inbound.decrypt(message)

      plaintext.should == "hello world"
      index.should == 0
      inbound.session_id.should == group.session_id
    end

    it "round-trips an olm 1:1 message" do
      alice = Async::Matrix::E2EE::Account.new
      bob   = Async::Matrix::E2EE::Account.new
      bob.generate_one_time_keys(1)
      bob_otk = bob.one_time_keys.values.first

      outbound = alice.create_outbound_session(bob.curve25519_key, bob_otk)
      type, body = outbound.encrypt("yo g")
      type.should == 0 # pre-key message

      session, plaintext = bob.create_inbound_session(alice.curve25519_key, body)
      plaintext.should == "yo g"

      reply_type, reply_body = session.encrypt("hello back")
      outbound.decrypt(reply_type, reply_body).should == "hello back"
    end

    it "verifies a valid ed25519 signature and rejects a bad one" do
      account   = Async::Matrix::E2EE::Account.new
      signature = account.sign("payload")

      Async::Matrix::E2EE.verify_signature(account.ed25519_key, "payload", signature).should == true
      Async::Matrix::E2EE.verify_signature(account.ed25519_key, "tampered", signature).should == false
    end

    it "survives a pickle round-trip" do
      key   = "0" * 32
      group = Async::Matrix::E2EE::GroupSession.new
      pickled = group.pickle(key)

      restored = Async::Matrix::E2EE::GroupSession.from_pickle(pickled, key)
      restored.session_id.should == group.session_id
    end
  end
end
