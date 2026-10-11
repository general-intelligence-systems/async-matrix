# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/e2ee/crypto"

require "async/matrix/e2ee_context"

describe Async::Matrix::E2EE::Crypto do
  include Async::Matrix::E2EEContext

  let(:bare) {subject.new}

  # Every one of these is what the machine calls, so a seam which answered any of them would be a seam an implementation could silently fail to provide.
  it "refuses to answer anything, because it holds no key material" do
    expect{bare.identity_keys}.to raise_exception(NotImplementedError)
    expect{bare.algorithms}.to raise_exception(NotImplementedError)
    expect{bare.sign({})}.to raise_exception(NotImplementedError)
    expect{bare.verify({}, key: "k", signature: "s")}.to raise_exception(NotImplementedError)
    expect{bare.generate_one_time_keys(1)}.to raise_exception(NotImplementedError)
    expect{bare.one_time_keys}.to raise_exception(NotImplementedError)
    expect{bare.published_one_time_keys!}.to raise_exception(NotImplementedError)
    expect{bare.one_time_key_target}.to raise_exception(NotImplementedError)
    expect{bare.generate_fallback_key}.to raise_exception(NotImplementedError)
    expect{bare.fallback_key}.to raise_exception(NotImplementedError)
    expect{bare.create_outbound_session("!r:localhost")}.to raise_exception(NotImplementedError)
    expect{bare.session_for("!r:localhost")}.to raise_exception(NotImplementedError)
    expect{bare.create_inbound_session("!r:localhost", session_id: "s", session_key: "k")}.to raise_exception(NotImplementedError)
    expect{bare.import_inbound_session("!r:localhost", session_id: "s", exported_key: "k")}.to raise_exception(NotImplementedError)
    expect{bare.export_session("s", index: 0)}.to raise_exception(NotImplementedError)
    expect{bare.encrypt("!r:localhost", "{}")}.to raise_exception(NotImplementedError)
    expect{bare.decrypt("!r:localhost", session_id: "s", ciphertext: "c")}.to raise_exception(NotImplementedError)
    expect{bare.dump("k")}.to raise_exception(NotImplementedError)
    expect{subject.load("{}", "k")}.to raise_exception(NotImplementedError)
  end

  # The keys are what Olm carries, so an implementation without this half can deliver nothing at all.
  it "refuses to answer the Olm half, which every key travels over" do
    expect{bare.session?("k")}.to raise_exception(NotImplementedError)
    expect{bare.open_session(identity_key: "k", one_time_key: "o")}.to raise_exception(NotImplementedError)
    expect{bare.accept_session(identity_key: "k", body: "b")}.to raise_exception(NotImplementedError)
    expect{bare.encrypt_to_device("k", "{}")}.to raise_exception(NotImplementedError)
    expect{bare.decrypt_from_device("k", type: 0, body: "b")}.to raise_exception(NotImplementedError)
  end

  # Nothing reaches the homeserver, because the keys to publish cannot be produced in the first place.
  it "stops a machine before it can publish anything" do
    bare_machine = Async::Matrix::E2EE::Machine.new(client, crypto: bare)

    expect{bare_machine.publish!}.to raise_exception(NotImplementedError)
    expect(client.keys.query_keys({user_id => []}).devices_of(user_id)).to be(:empty?)
  end

  # The machine is written against this class, so an implementation which satisfies it satisfies the machine.
  it "declares exactly what an implementation must provide" do
    expect(crypto).to be_a(subject)
    expect(machine.publish!.count("signed_curve25519")).to be == crypto.one_time_key_target
  end
end
