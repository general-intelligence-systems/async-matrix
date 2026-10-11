# Matrix end-to-end encryption specification

The official specification material for end-to-end encryption, vendored so that the flow can be read beside the code which implements it.

This is **input you read, not output you produce**: it is a copy of upstream, and the way to change it is to re-vendor at a newer commit.

## Provenance

| | |
| --- | --- |
| Source | https://github.com/matrix-org/matrix-spec |
| Commit | `a484823f68d29671a968410d8ad98bb00c554af7` |
| Dated | 2026-10-09 |
| Vendored | 2026-10-11 |
| Licence | Apache License 2.0, the same as this project |

Copyright belongs to The Matrix.org Foundation C.I.C. and the contributors to the specification.

Upstream paths are preserved, so any file here is `<repository>/<path>` at that commit.

## Why these files

`MATRIX_API_VERSIONS.txt` and the generated `schemas/` describe the *surface* of each endpoint, version by version. They do not describe the protocol a client must run to use that surface: which event unlocks which other event, what must be validated, and what must be remembered. These files do.

The `x-addedInMatrixVersion` and `x-changedInMatrixVersion` annotations in the schemas, and the `added-in` and `changed-in` markers in the prose, say which version layer a behaviour belongs in.

## Layout

### Prose

| File | What it answers |
| --- | --- |
| `content/client-server-api/modules/end_to_end_encryption.md` | the whole flow: key distribution, device verification, cross-signing, key sharing, backups, history sharing, both messaging algorithms, and the withheld report |
| `content/client-server-api/modules/secrets.md` | secret storage and secret sharing, which carry the cross-signing and backup private keys |
| `content/client-server-api/modules/send_to_device.md` | the transport every key-bearing event travels over |
| `content/client-server-api/modules/device_management.md` | the device list the keys hang from |
| `content/olm-megolm/olm.md` | the Olm double ratchet: the pairwise channel, and the pre-key and normal message formats |
| `content/olm-megolm/megolm.md` | the Megolm hash ratchet: the group session, and its message format |
| `content/olm-megolm/_index.md` | how the two ratchets relate |
| `content/appendices.md` | canonical JSON, signing JSON, unpadded Base64 and the cryptographic key representation |

### Events

Under `data/event-schemas/schema/`, one file per event, plus the `core-event-schema/` and `components/` they reference. Every reference resolves within this directory.

The timeline and state events:

- `m.room.encryption.yaml` — the state event which turns a room encrypted, and carries the rotation policy.
- `m.room.encrypted.yaml` — the ciphertext envelope, used for both algorithms and on both transports.
- `m.room.message$m.key.verification.request.yaml` — a verification request made in a room rather than to a device.

The key-bearing to-device events:

- `m.room_key.yaml` — the Megolm session, shared over Olm.
- `m.room_key.withheld.yaml` — the report that a session was deliberately not shared, and the `code` values it can carry.
- `m.room_key_request.yaml` — asking another device for a session, and cancelling the ask.
- `m.forwarded_room_key.yaml` — answering that ask, with the forwarding chain.
- `m.dummy.yaml` — announcing a replacement Olm session after one is found corrupt.
- `m.room_key_bundle.yaml` — the bundle of sessions shared with a newly invited user.

The verification events, which share one framework and add their own steps:

- `m.key.verification.request.yaml`, `.ready.yaml`, `.start.yaml`, `.accept.yaml`, `.key.yaml`, `.mac.yaml`, `.done.yaml`, `.cancel.yaml`
- `m.key.verification.start$m.sas.v1.yaml` — the short authentication string method.
- `m.key.verification.start$m.reciprocate.v1.yaml` — the QR code method.
- `m.key.verification.m.relates_to.yaml` — the framing which carries a verification in a room.

The secrets and backup events:

- `m.secret.request.yaml` and `m.secret.send.yaml` — asking one of our own verified devices for a named secret, and the answer.
- `m.key_backup.yaml` — the account data recording whether the user wants key backup.

### Endpoints and definitions

Under `data/api/client-server/`:

- `keys.yaml` — `/keys/upload`, `/keys/query`, `/keys/claim` and `/keys/changes`.
- `cross_signing.yaml` — `/keys/device_signing/upload` and `/keys/signatures/upload`.
- `key_backup.yaml` — the `/room_keys` endpoints.
- `to_device.yaml` — `/sendToDevice`.
- `device_management.yaml` — `/devices`.

Under `data/api/client-server/definitions/`, the structures those endpoints and events are built from. The ones which matter most to a reader:

- `olm_plaintext.yaml` — what an Olm-encrypted event decrypts to, and so the fields which must be validated before it is believed.
- `device_keys.yaml` and `cross_signing_key.yaml` — the signed identities.
- `one_time_keys.yaml` — the keys which establish an Olm session.
- `room_key_bundle.yaml` — the bundle shared on invite.
- `encrypted_file.yaml` — how an attachment, and a key bundle, is encrypted.
- `key_backup_auth_data.yaml`, `key_backup_session_data.yaml`, `key_backup_data.yaml`, `room_key_backup.yaml` — the backup.
- `megolm_export_session_data.yaml` — the manual export, which carries the `shared_history` flag too.

### Data

- `data-definitions/sas-emoji.json` — the 64 emoji a short authentication string is drawn from, with their descriptions.
