---
layout: default
title: Encryption (E2EE)
nav_order: 2
description: Olm/Megolm end-to-end encryption via a native vodozemac binding.
---

# Encryption (E2EE)

async-matrix ships end-to-end encryption primitives — Olm (1:1) and Megolm (group) — as `Async::Matrix::E2EE`, backed by a native Rust binding over [vodozemac](https://github.com/matrix-org/vodozemac), the same crypto library used by Element. The binding is built with [magnus](https://github.com/matsadler/magnus) and compiled via rake-compiler; requiring `async/matrix` loads the compiled object.

{: .note }
E2EE exposes the cryptographic building blocks. It is what a bridge or bot uses to participate in encrypted rooms; it is not a turnkey "encrypt my bot" switch.

## Account and identity keys

An `Account` holds a device's long-term identity and its one-time keys:

```ruby
account = Async::Matrix::E2EE::Account.new
account.curve25519_key    # => base64 identity (Curve25519) key
account.ed25519_key       # => base64 signing (Ed25519) key

account.generate_one_time_keys(1)   # publish these so others can start sessions
```

## Olm — 1:1 sessions

Establish a session from published identity + one-time keys, then exchange messages:

```ruby
# Alice starts an outbound session to Bob
outbound = alice.create_outbound_session(bob.curve25519_key, bob_one_time_key)
type, body = outbound.encrypt("yo g")

# Bob accepts it inbound and decrypts
session, plaintext = bob.create_inbound_session(alice.curve25519_key, body)
plaintext   # => "yo g"

# Replies flow back over the same session
reply_type, reply_body = session.encrypt("hello back")
outbound.decrypt(reply_type, reply_body)   # => "hello back"
```

## Megolm — group sessions

Room messages use Megolm. The sender holds a `GroupSession`; recipients rebuild an `InboundGroupSession` from its exported session key:

```ruby
group = Async::Matrix::E2EE::GroupSession.new
message = group.encrypt("hello world")        # => base64 megolm ciphertext

inbound = Async::Matrix::E2EE::InboundGroupSession.new(group.session_key)
plaintext, index = inbound.decrypt(message)   # => ["hello world", 0]
```

The returned `index` is the Megolm ratchet index — useful for detecting replays and ordering.

## Signature verification

Verify Ed25519 signatures (e.g. on device keys) with the module function:

```ruby
signature = account.sign("payload")

Async::Matrix::E2EE.verify_signature(account.ed25519_key, "payload", signature)   # => true
Async::Matrix::E2EE.verify_signature(account.ed25519_key, "tampered", signature)  # => false
```

## Building requirement

Because the binding is native, building the gem needs a Rust toolchain (the `magnus` extension is compiled at install time). The `encryption` section of the [config schema]({% link _advanced/configuration.md %}) carries the bridge-level encryption settings that sit on top of these primitives.
