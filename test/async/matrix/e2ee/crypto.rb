# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/e2ee/crypto"
require "async/matrix/e2ee/plaintext"

describe Async::Matrix::E2EE::Crypto do
  let(:crypto) {subject.new}

  # Every one of these is what the machine calls, so a seam which answered any of them would be a seam an implementation could silently fail to provide.
  it "refuses to answer anything, because it holds no key material" do
    expect{crypto.identity_keys}.to raise_exception(NotImplementedError)
    expect{crypto.algorithms}.to raise_exception(NotImplementedError)
    expect{crypto.sign({})}.to raise_exception(NotImplementedError)
    expect{crypto.verify({}, key: "k", signature: "s")}.to raise_exception(NotImplementedError)
    expect{crypto.generate_one_time_keys(1)}.to raise_exception(NotImplementedError)
    expect{crypto.one_time_keys}.to raise_exception(NotImplementedError)
    expect{crypto.published_one_time_keys!}.to raise_exception(NotImplementedError)
    expect{crypto.one_time_key_target}.to raise_exception(NotImplementedError)
    expect{crypto.create_outbound_session("!r:localhost")}.to raise_exception(NotImplementedError)
    expect{crypto.session_for("!r:localhost")}.to raise_exception(NotImplementedError)
    expect{crypto.create_inbound_session("!r:localhost", session_id: "s", session_key: "k")}.to raise_exception(NotImplementedError)
    expect{crypto.encrypt("!r:localhost", "{}")}.to raise_exception(NotImplementedError)
    expect{crypto.decrypt("!r:localhost", session_id: "s", ciphertext: "c")}.to raise_exception(NotImplementedError)
  end

  # The machine is written against this class, so an implementation which satisfies it satisfies the machine.
  it "declares exactly what an implementation must provide" do
    expect(Async::Matrix::E2EE::Plaintext.new).to be_a(subject)
  end
end
