# Feature Comparison: async-matrix (Ruby) v0.2.0 vs mautrix/go v0.27.0

## Overview

|                      | **async-matrix (Ruby)**          | **mautrix/go**                        |
| -------------------- | -------------------------------- | ------------------------------------- |
| **Language**         | Ruby >= 3.3                      | Go 1.25+                             |
| **License**          | Apache 2.0                       | MPL 2.0                              |
| **Maturity**         | v0.2.0, early-stage              | v0.27.0, production-grade            |
| **Primary Focus**    | AppService bots                  | Full Matrix SDK + bridge framework   |
| **Concurrency**      | Fiber-based (async gem)          | Goroutines                           |
| **Used By**          | -                                | gomuks, mautrix-whatsapp, go-neb, 10+ bridges |

---

## 1. Application Service API

| Feature                                  | Ruby                    | Go                                |
| ---------------------------------------- | ----------------------- | --------------------------------- |
| Transaction endpoint (`PUT /transactions`) | YES                   | YES                               |
| Transaction deduplication                | YES (in-memory LRU)     | YES (cache)                       |
| User query endpoint                      | YES (always 200)        | YES (pluggable handler)           |
| Room alias query endpoint                | YES (always 404)        | YES (pluggable handler)           |
| Ping endpoint (MSC2659)                  | YES                     | YES                               |
| hs_token authentication                  | YES (timing-safe)       | YES                               |
| Ephemeral event support (MSC2409)        | YES                     | YES                               |
| WebSocket transport                      | NO                      | YES (Beeper)                      |
| Intent API (ghost user management)       | NO                      | YES (auto-register, auto-join, profile) |
| Health/readiness endpoints               | NO                      | YES (`/live`, `/ready`)           |
| Device assertion (MSC3202)               | NO                      | YES                               |
| Event processor/dispatcher               | YES (schema-aware)      | YES                               |
| Double puppet markers                    | NO                      | YES                               |
| MSC4190 device creation                  | NO                      | YES                               |

---

## 2. Client-Server API

> **Note:** As of v0.2.0, `client.api` provides runtime-generated access to every
> Client-Server API endpoint. It loads the official Matrix OpenAPI 3.1.0 schemas at
> boot, validates paths against them, and exposes endpoints via method chains:
>
> ```ruby
> client.api.createRoom.post(name: "Pub", preset: "public_chat")
> client.api.rooms("!abc:ex.com").send("m.room.message", txn).put(msgtype: "m.text", body: "hi")
> client.api.rooms("!abc:ex.com").messages.get(dir: "b", limit: 10)
> client.api.profile("@user:ex.com").displayname.put(displayname: "Bob")
> ```
>
> Features marked "via `client.api`" below are available through this mechanism.
> They call the correct endpoint with path validation but do not provide
> higher-level abstractions (typed responses, retry logic, etc.).

### Authentication

| Feature                          | Ruby                    | Go                        |
| -------------------------------- | ----------------------- | ------------------------- |
| Login (password/token/SSO)       | YES (`api.login.post`)  | YES (8+ auth types)       |
| Logout                           | YES (`api.logout.post`) | YES                       |
| Register                         | YES (`api.register.post`)| YES (full UIA)           |
| Whoami                           | YES                     | YES                       |
| Well-known discovery             | YES                     | YES                       |

### Sync

| Feature                          | Ruby                            | Go                        |
| -------------------------------- | ------------------------------- | ------------------------- |
| Long-polling `/sync`             | YES (`api.sync.get`)            | YES (full syncer w/ store)|
| Sync filters                     | YES (`api.user(...).filter.post`) | YES                     |
| Streaming sync (Beeper)          | NO                              | YES                       |

### Messaging

| Feature                              | Ruby                  | Go  |
| ------------------------------------ | --------------------- | --- |
| Send text message                    | YES                   | YES |
| Send HTML message                    | YES                   | YES |
| Send notice                          | YES                   | YES |
| Send generic message event           | YES                   | YES |
| Send state event                     | YES (via `client.api`) | YES |
| Get event                            | YES (via `client.api`) | YES |
| Get room state                       | YES (via `client.api`) | YES |
| Message pagination (`/messages`)     | YES (via `client.api`) | YES |
| Event context                        | YES (via `client.api`) | YES |
| Auto-encrypt if room is encrypted    | NO                    | YES |

### Room Operations

| Feature                              | Ruby                   | Go                    |
| ------------------------------------ | ---------------------- | --------------------- |
| Join room                            | YES                    | YES (with `via`)      |
| Leave room                           | YES                    | YES (with reason)     |
| Create room                          | YES (via `client.api`) | YES (full options)    |
| Invite user                          | YES (via `client.api`) | YES                   |
| Kick user                            | YES (via `client.api`) | YES                   |
| Ban/unban user                       | YES (via `client.api`) | YES                   |
| Knock on room                        | YES (via `client.api`) | YES                   |
| Forget room                          | YES (via `client.api`) | YES                   |
| Room aliases (set/delete/resolve)    | YES (via `client.api`) | YES                   |
| Room directory listing               | YES (via `client.api`) | YES                   |
| Room summary (MSC3266)               | NO                     | YES                   |
| Redact event                         | YES (via `client.api`) | YES                   |
| Report event                         | YES (via `client.api`) | YES                   |

### Profile

| Feature                              | Ruby                   | Go  |
| ------------------------------------ | ---------------------- | --- |
| Set display name                     | YES                    | YES |
| Get display name                     | YES (via `client.api`) | YES |
| Set/get avatar                       | YES (via `client.api`) | YES |
| Full profile get                     | YES (via `client.api`) | YES |
| Arbitrary profile fields (MSC4133)   | NO                     | YES |

### Presence, Typing, Read Receipts

| Feature                              | Ruby                   | Go                     |
| ------------------------------------ | ---------------------- | ---------------------- |
| Set/get presence                     | YES (via `client.api`) | YES                    |
| Send typing notification             | YES (via `client.api`) | YES                    |
| Receive typing (ephemeral)           | YES (dispatch only)    | YES                    |
| Send receipt                         | YES (via `client.api`) | YES (thread-aware)     |
| Set read markers                     | YES (via `client.api`) | YES                    |
| Receive receipts (ephemeral)         | YES (dispatch only)    | YES                    |

### Other Client-Server APIs

| Feature                              | Ruby                   | Go  |
| ------------------------------------ | ---------------------- | --- |
| Account data (global + per-room)     | YES (via `client.api`) | YES |
| Device management (list/get/delete)  | YES (via `client.api`) | YES |
| Push rules (get/set/delete)          | YES (via `client.api`) | YES (full engine) |
| Send to-device events                | YES (via `client.api`) | YES |
| Get relations (paginated)            | YES (via `client.api`) | YES |
| Delayed events (MSC4140)             | NO                     | YES |
| TURN server credentials              | YES (via `client.api`) | YES |
| Server capabilities/versions         | YES (via `client.api`) | YES (r0.0.0 -- v1.18) |
| Synapse admin APIs                   | NO                     | YES (register, users, rooms) |

---

## 3. Server-Server (Federation) API

| Feature                                           | Ruby | Go  |
| ------------------------------------------------- | ---- | --- |
| Federation client                                 | NO   | YES |
| Server name resolution (`.well-known` + SRV)      | NO   | YES |
| Server authentication (signature validation)      | NO   | YES |
| Signing key management (Ed25519)                  | NO   | YES |
| PDU processing (canonical JSON, hashing, signing) | NO   | YES |
| Event authorization rules (room v1--v12)          | NO   | YES |
| Send/receive transactions                         | NO   | YES |
| Auth chain retrieval                              | NO   | YES |
| State retrieval                                   | NO   | YES |
| Join flow (make_join/send_join)                   | NO   | YES |
| Backfill via federation                           | NO   | YES |

---

## 4. End-to-End Encryption

| Feature                                | Ruby | Go  |
| -------------------------------------- | ---- | --- |
| Olm sessions (device-to-device)        | NO   | YES |
| Megolm sessions (group)                | NO   | YES |
| Automatic encrypt/decrypt              | NO   | YES |
| Pure Go Olm implementation (goolm)     | N/A  | YES |
| libolm C bindings (optional)           | NO   | YES |
| Session rotation policies              | NO   | YES |
| Key sharing with trust controls        | NO   | YES |
| Olm session unwedging                  | NO   | YES |
| Replay attack detection                | NO   | YES |
| Cross-signing (master/self/user keys)  | NO   | YES |
| Key verification (SAS - emoji/decimal) | NO   | YES |
| Key verification (QR code)             | NO   | YES |
| SSSS (Secure Secret Storage)           | NO   | YES |
| Key backup (Megolm)                    | NO   | YES |
| Key export/import                      | NO   | YES |
| Encrypted attachments (AES-CTR)        | NO   | YES |
| Crypto store (SQL, memory)             | NO   | YES (19 migrations) |
| CryptoHelper (high-level integration)  | NO   | YES |

---

## 5. Media Handling

| Feature                          | Ruby                   | Go  |
| -------------------------------- | ---------------------- | --- |
| Upload files                     | YES (via `client.api`) | YES |
| Download files                   | YES (via `client.api`) | YES |
| Async upload (MSC2246)           | NO                     | YES |
| Encrypted media                  | NO                     | YES |
| Content URI parsing/handling     | NO                     | YES (full type) |
| URL preview (og: tags)           | YES (via `client.api`) | YES |
| Media config (upload limits)     | YES (via `client.api`) | YES |
| Authenticated media (MSC3916)    | YES (via `client.api`) | YES |
| Media proxy server               | NO                     | YES |
| Thumbnail info / blurhash        | NO                     | YES |

---

## 6. Event Type Coverage

| Category                   | Ruby                                          | Go                          |
| -------------------------- | --------------------------------------------- | --------------------------- |
| Event schema validation    | YES -- 76 YAML schemas via `json_schemer`     | 75+ typed Go structs        |
| Variant schema validation  | YES -- 14 variant schemas (msgtype, algorithm) | Via typed structs           |
| State event types          | 25+ validated via official spec schemas       | 25+ with typed content      |
| Message event types        | 20+ validated via official spec schemas       | 20+ with typed content      |
| Ephemeral event types      | 3+ validated via official spec schemas        | 3+ with typed content       |
| To-device event types      | 15+ validated via official spec schemas       | 15+ with typed content      |
| Account data event types   | 15+ validated via official spec schemas       | 15+ with typed content      |
| VoIP/call events           | 7 validated (invite/answer/candidates/etc.)   | 7 typed                     |
| Verification events        | 8+ validated (SAS + QR)                       | 8+ typed (SAS + QR)         |
| Poll events (MSC3381)      | None                                          | YES (start/response/end)    |
| Image packs / custom emoji | None                                          | YES                         |
| Moderation policy events   | 3 validated (user/room/server)                | YES                         |
| Custom format validators   | 6 (mx-user-id, mx-room-id, mx-event-id, etc.) | Via typed IDs              |

> **Schema-driven approach:** Rather than hand-coding typed structs for each event type
> (as mautrix/go does), async-matrix loads the **official matrix-org/matrix-spec YAML
> schemas** at runtime and validates events against them using `json_schemer`. This means:
>
> - **Always up-to-date**: run `bin/fetch-matrix-schemas` to pull the latest spec
> - **76 base schemas + 14 variants** covering every event type in the Matrix spec
> - **Full `$ref` resolution** across schema files (core envelopes, components, API definitions)
> - **Automatic variant matching**: `m.room.message` with `msgtype: "m.text"` also validates
>   against the `m.room.message$m.text` variant schema
> - **Schema introspection**: `event.content_properties` returns the list of fields defined
>   by the schema for that event type
>
> ```ruby
> event = Schema.parse(raw_hash)     # parse into schema-aware Event
> event.valid?                       # validate against the spec
> event.valid!                       # raise ValidationError with detailed errors
> event.schema                       # the JSONSchemer::Schema for this event type
> event.content_properties           # ["membership", "avatar_url", "displayname", ...]
> event.content.membership           # dynamic access to any schema-defined field
> ```
>
> The `Content` class provides dynamic method access to **all** fields present in the raw
> event data (not just `msgtype`, `body`, `membership`). For `m.room.member` events, you
> can call `event.content.avatar_url`, `event.content.displayname`, `event.content.is_direct`,
> etc. directly.
>
> **Trade-off vs mautrix/go:** Go provides compile-time type safety and IDE autocompletion
> via hand-coded structs. Ruby provides runtime validation against the canonical spec source,
> meaning new event types or field changes are picked up by re-fetching schemas without any
> code changes.

---

## 7. Bridge Framework

| Feature                              | Ruby                              | Go                                |
| ------------------------------------ | --------------------------------- | --------------------------------- |
| Bot DSL (`on event_type do...`)      | YES                               | NO (different paradigm)           |
| Handler protocol                     | YES (duck-typed)                  | YES (interface-based)             |
| Multi-bot per appservice             | YES                               | YES                               |
| Bridge v2 framework                  | NO                                | YES (comprehensive)               |
| Network connector interface          | NO                                | YES (20+ handler interfaces)      |
| Portal/Ghost/User entity management  | NO                                | YES                               |
| Login flow framework (multi-step)    | NO                                | YES                               |
| Commands framework                   | NO                                | YES                               |
| Bridge state monitoring              | NO                                | YES                               |
| Message delivery status tracking     | NO                                | YES                               |
| Relay mode                           | NO                                | YES                               |
| Backfill queue (database-backed)     | NO                                | YES                               |
| Disappearing messages                | NO                                | YES                               |
| Double puppeting                     | NO                                | YES                               |
| Room capabilities/features           | NO                                | YES                               |
| Provisioning API                     | NO                                | YES                               |
| Per-message profiles                 | NO                                | YES                               |
| Contact listing / user search        | NO                                | YES                               |
| Group creation                       | NO                                | YES                               |
| Personal filtering spaces            | NO                                | YES                               |

---

## 8. Database / Persistence

| Feature                              | Ruby                    | Go                          |
| ------------------------------------ | ----------------------- | --------------------------- |
| Database backends                    | None                    | PostgreSQL, SQLite          |
| Schema migrations                    | None                    | YES (versioned)             |
| Transaction store                    | In-memory LRU (1024)    | Cache                       |
| State store (members, power levels)  | None                    | YES (SQL, 10 migrations)    |
| Crypto store                         | None                    | YES (SQL, 19 migrations)    |
| Bridge database (portals, messages)  | None                    | YES (full schema)           |
| Metadata extension system            | None                    | YES (MetaTypes, MetaMerger) |

---

## 9. HTTP Client Features

| Feature                              | Ruby                    | Go                                |
| ------------------------------------ | ----------------------- | --------------------------------- |
| Connection pooling                   | YES (async-http)        | YES                               |
| Automatic retries                    | PARTIAL (connection-level) | YES (connection + status-code backoff) |
| Rate limit handling (429)            | NO                      | YES (Retry-After parsing)         |
| Gateway error retries (502/503/504)  | NO                      | YES                               |
| Response size limits                 | NO                      | YES (512 MiB default)             |
| Request/response hooks               | NO                      | YES                               |
| Streaming responses                  | NO                      | YES                               |
| WebSocket client                     | NO                      | YES                               |

> **Retry semantics in async-http:** `Async::HTTP::Client` provides built-in
> connection-level retries for idempotent requests (GET, HEAD, PUT, DELETE, OPTIONS,
> TRACE), configurable via the `retries:` constructor argument (default: 3, set to 0
> to disable). As of async-http v0.95.0, `Protocol::HTTP::RefusedError` enables safe
> retry of *even non-idempotent* requests when the server provably never processed
> them (HTTP/2 `REFUSED_STREAM`, `GOAWAY`, write failures before any bytes were sent).
>
> What async-http does **not** cover is application-level retry on HTTP error status
> codes (429 rate limits with `Retry-After`, 502/503/504 gateway errors) with
> exponential backoff and jitter. That remains the gap vs. mautrix/go and needs to be
> implemented in the SDK layer.

---

## 10. Other Features

| Feature                              | Ruby                           | Go                                |
| ------------------------------------ | ------------------------------ | --------------------------------- |
| Logging                              | Console gem (structured)       | zerolog (structured)              |
| ID types                             | Plain strings                  | Full typed IDs (UserID, RoomID, EventID, etc.) |
| Matrix URI scheme (MSC2312)          | NO                             | YES                               |
| Spaces support                       | NO                             | YES (hierarchy, child/parent, filtering) |
| Room versions (feature flags)        | NO                             | YES (v1--v12)                     |
| Format/HTML helpers                  | NO                             | YES (HTML parser, Markdown-to-Matrix) |
| Testing utilities                    | 316 inline tests (Scampi)      | Mock server, extensive tests      |
| Documentation                        | Auto-generated event reference | Code docs                         |
| Docker examples                      | YES (echo bot, multi-bot)      | N/A (library)                     |
| Config system                        | YAML with validation           | YAML with upgrader system         |
| Spec version awareness               | NO                             | YES (r0.0.0 -- v1.18, feature flags) |

---

## 11. What async-matrix Has That Is Unique

- **Fiber-based async Ruby architecture** built on the Socketry ecosystem (async, async-http, falcon)
- **Inline co-located test pattern** using Scampi (`test do ... end` blocks in source files)
- **Bot DSL** with declarative `on` syntax and built-in filters (`msgtype:`, `not_from: :self`)
- **Schema-driven event parsing and validation** -- loads the official matrix-org/matrix-spec YAML schemas (76 base + 14 variants) at runtime via `json_schemer`, with full `$ref` resolution, custom Matrix format validators, automatic variant matching, and `Schema.parse(hash)` as the single entry point. Events arriving through the appservice transaction pipeline are automatically schema-aware. Run `bin/fetch-matrix-schemas` to stay current with the spec -- zero code changes needed.
- **Auto-generated Matrix event type documentation** from upstream `matrix-org/matrix-spec` YAML schemas
- **Runtime-generated full API from OpenAPI schemas** -- loads the official Matrix Client-Server OpenAPI 3.1.0 specs at boot, builds a validated path tree, and exposes every endpoint via `client.api` method chains terminated by `.get()`, `.post()`, `.put()`, `.delete()`. Chains are validated against the spec -- invalid paths raise `InvalidEndpointError`. Powered by [StringBuilder](https://github.com/nathanhoad/string_builder) and `BasicObject` for zero method-name conflicts (even `send`, `display`, `format`, etc. work as path segments).
- **Docker-ready example stack** with Synapse + FluffyChat + nginx for local development
- **Timing-safe hs_token authentication** using constant-time byte comparison

---

## 12. Feature Gap Analysis (Prioritized)

### Tier 1 -- Critical for Bridge Development

These are table-stakes features that any production bridge SDK needs:

| Feature                          | Effort Estimate | Status | Notes |
| -------------------------------- | --------------- | ------ | ----- |
| Intent API (ghost user mgmt)     | Medium          | TODO   | Auto-register, auto-join, profile sync for ghost users |
| Database persistence layer       | Large           | TODO   | Portal, ghost, message, user tables; PostgreSQL + SQLite |
| Room creation                    | Small           | **DONE** | `client.api.createRoom.post(...)` |
| Invite / kick / ban              | Small           | **DONE** | `client.api.rooms(id).invite.post(...)` etc. |
| Send state events                | Small           | **DONE** | `client.api.rooms(id).state(type, key).put(...)` |
| Get room state                   | Small           | **DONE** | `client.api.rooms(id).state.get` |
| Redact events                    | Small           | **DONE** | `client.api.rooms(id).redact(eid, txn).put(...)` |
| Message status tracking          | Medium          | TODO   | Delivery confirmations back to the remote network |
| Backfill support                 | Large           | TODO   | Historical message import with deduplication |
| Double puppeting                 | Medium          | TODO   | User's own messages bridged without duplication |

### Tier 2 -- High Value

| Feature                          | Effort Estimate | Status | Notes |
| -------------------------------- | --------------- | ------ | ----- |
| Typed event content structs      | Medium          | **DONE** (schema-driven) | 76 event types validated via official YAML schemas + `Schema.parse` |
| Media upload / download          | Medium          | **DONE** | `client.api.upload.post(...)`, `client.api.download(...)` via full API |
| Status-code retry / rate-limit   | Small           | TODO   | 429 Retry-After + 502/503/504 backoff (connection-level retries already provided by async-http) |
| Sync client (`/sync`)            | Large           | **DONE** (endpoint) | `client.api.sync.get(...)` -- syncer/store still needed |
| Message pagination (`/messages`) | Small           | **DONE** | `client.api.rooms(id).messages.get(dir: "b", limit: 10)` |
| Account data (global + per-room) | Small           | **DONE** | `client.api.user(uid).account_data(type).put(...)` |
| Typed ID types                   | Medium          | TODO   | UserID, RoomID, EventID with validation |
| Room capabilities                | Medium          | TODO   | Per-room feature detection for bridge connectors |
| Provisioning API                 | Medium          | TODO   | Identifier resolution, contact listing, group creation |

### Tier 3 -- Important

| Feature                          | Effort Estimate | Notes |
| -------------------------------- | --------------- | ----- |
| End-to-end encryption            | Very Large      | Olm/Megolm, cross-signing, key backup, SSSS |
| Encrypted media                  | Medium          | AES-CTR attachment encrypt/decrypt |
| Push rules engine                | Large           | Full condition evaluation engine |
| Spaces support                   | Medium          | Hierarchy, child/parent state events |
| Format / HTML helpers            | Small           | HTML-to-plaintext, Markdown-to-Matrix-HTML |
| Disappearing messages            | Medium          | Timer tracking, periodic cleanup |
| Commands framework               | Medium          | User-facing `!command` processing |
| Login flow framework             | Medium          | Multi-step auth for remote networks |

### Tier 4 -- Moderate

| Feature                          | Effort Estimate | Notes |
| -------------------------------- | --------------- | ----- |
| Federation API                   | Very Large      | Rarely needed for bridges |
| VoIP event types                 | Small           | Typed structs for call events |
| Synapse admin APIs               | Small           | Registration, user/room management |
| Spec version tracking            | Small           | Feature detection based on server version |
| Room version feature flags       | Small           | v1--v12 behavioral differences |
| Matrix URI scheme                | Small           | `matrix:` URI parsing (MSC2312) |

### Tier 5 -- Nice to Have

| Feature                          | Effort Estimate | Notes |
| -------------------------------- | --------------- | ----- |
| Mock server for testing          | Medium          | Test harness for Matrix interactions |
| WebSocket appservice transport   | Medium          | Non-standard, Beeper-specific |
| Key verification UI helpers      | Large           | SAS emoji, QR code flows |
| Poll events                      | Small           | MSC3381 poll start/response/end |
| Image packs / custom emoji       | Small           | Sticker/emoji pack management |

---

## 13. Rough Numeric Comparison

| Metric                           | async-matrix (Ruby)                      | mautrix/go          |
| -------------------------------- | ---------------------------------------- | ------------------- |
| Source files                     | ~25                                      | ~300+               |
| Lines of code (estimated)        | ~3,000                                   | ~100,000+           |
| Event types validated             | 76 base + 14 variants (schema-driven)    | 75+ (hand-coded structs) |
| Client-Server API methods        | 7 hand-written + full API via `client.api` (all 71 OpenAPI endpoint files) | 80+  |
| Federation API methods           | 0                                        | 10+                 |
| Database tables                  | 0                                        | 30+                 |
| Schema migrations                | 0                                        | 30+                 |
| Test count                       | 316                                      | Hundreds            |
| Bridge handler interfaces        | 1 (duck-typed)                           | 20+                 |
| Room versions supported          | 0                                        | 12                  |
| Spec versions tracked            | 0                                        | 20+ (r0.0.0--v1.18) |
