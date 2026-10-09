# Changelog

All notable changes to **async-matrix** are documented here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- **Breaking: the client classes moved under `Client::`, without the suffix.**
  `Async::Matrix::AppServiceClient` is now `Async::Matrix::Client::AppService`,
  `DoublePuppetClient` is `Client::DoublePuppet`, and `MediaClient` is
  `Client::Media` — every client lives in `lib/async/matrix/client/*.rb`, named
  for its path. The old constant names are gone.

## [3.0.1] - 2026-10-09

Encryption is now usable end to end. The message *format* layer moved to a new
`Protocol::Matrix` namespace that does no IO, `Async::Matrix::DeviceStore`
holds one device's key material and reads anything it has a key for, and
`Client#sync` streams decrypted messages off a homeserver. The old
`Async::Matrix` constant names still work.

### Added

- **`Protocol::Matrix`** — the format layer, in the namespace the Socketry
  convention puts it in (`protocol-http` owns the format, `async-http` binds it
  to IO). Everything under it can be unit tested with a Hash: no network, no
  homeserver, and no crypto. `require "async/matrix"` loads it, and
  `require "protocol/matrix"` loads it alone. New constants:
  - **`EncryptedMessage`** — an `m.room.encrypted` event of either algorithm
    (`OLM`, `MEGOLM`). `.encrypted?(data)` classifies a raw hash;
    `#ciphertext_for`, `#addressed_to?`, `#message_type` and `#prekey?` answer
    the Olm addressing questions; `#decrypt!(session)` then makes `#type`,
    `#content` and `#message_index` readable. The builders —
    `.megolm_content`, `.olm_content`, `.room_payload`, `.olm_payload`,
    `.room_key_payload` — produce the wire shapes.
  - **`MessageBatch`** — `.from_sync(response)` and
    `.from_transaction(transaction)` turn either wire format into one
    single-pass stream of messages. **To-device messages are always read
    first**, so an `m.room_key` in a batch unlocks the timeline event later in
    the same batch on its first pass. Not rewindable: `#read` answers `nil`
    forever once drained, because decrypting ratchets a session forward.
  - **`Keys`** — builds and verifies the signed key objects
    `/keys/upload` wants: `.device_keys`, `.one_time_keys`, `.fallback_keys`,
    `.signed_key`, plus `.identity_key`, `.fingerprint` and
    `.valid_device_keys?` for reading somebody else's.
  - **`Signing`** and **`CanonicalJson`** — canonical JSON encoding per the
    spec (`.encode`, `.signable_bytes`, with the ±2^53 integer bounds enforced)
    and signatures over it (`.sign`, `.verify`, `.signed_by?`, `.key_id`). The
    signer and verifier are injected, so neither module names a crypto library.
  - **`SecretStorage`** — 4S (`m.secret_storage.v1.aes-hmac-sha2`):
    `.decode_recovery_key` / `.encode_recovery_key` for the base58 key the user
    writes down, `.derive_from_passphrase`, `.valid_key?` to check a key against
    `key_info` before trusting it, and `.decrypt_secret`.
  - **`KeyBackup`** — server-side key backup
    (`m.megolm_backup.v1.curve25519-aes-sha2`): `.decrypt_session`,
    `.public_key_for` and `.key_matches?`. The sessions it yields feed
    `InboundGroupSession.import`, added in 2.1.0.
  - **`Error`** — see *Changed*.
- **`Async::Matrix::DeviceStore`** — one device's Olm account, its 1:1 sessions
  and every Megolm room key it has accumulated; this is what you hand to a sync
  client. `#decrypt(message)` returns the message if it could be read and `nil`
  if not, `#encrypt(room_id:, type:, content:)` produces megolm content and
  rotates the session on `DEFAULT_ROTATION_MESSAGES`/`DEFAULT_ROTATION_MS`,
  and `#absorb(payload)` takes in an `m.room_key` or `m.forwarded_room_key`.
  `#device_keys`, `#generate_one_time_keys`, `#generate_fallback_key` and
  `#needs_one_time_keys?(server_count)` cover the publishing side.

  It persists nothing: the crypto primitives are injected already unpickled
  (`account:` is duck-typed, `e2ee:` is any module providing
  `InboundGroupSession`), and every ratchet step is reported through `#changes`
  / `#changed?` / `#flush_changes!` for the caller to write where it likes.
  `#export(pickle_key)` pickles the lot. It also raises `ReplayError` on a
  repeated megolm message index and `RoomMismatchError` on a session used for
  the wrong room.
- **`Client#sync`**, returning a **`Client::Sync`** — a stream of messages,
  decrypted on the way through by the `store:` you pass. `#each` yields room
  messages *only*: to-device events are fed to the store rather than yielded,
  which is how room keys arrive, and `#next_batch` is the cursor to resume
  from. `#one_time_keys_count` surfaces what the server says it still holds.
  A failed request raises rather than retrying — a homeserver that is down is
  policy for whatever drives the loop.
- **`Client::Encryption`**, mixed into `Client` — `#register_user`,
  `#create_device`, `#upload_keys`, `#upload_cross_signing_keys`,
  `#upload_signatures`, `#query_keys`, `#claim_keys` and `#send_to_device`.
  Until `#upload_keys` has run the device is invisible and every message in an
  encrypted room stays ciphertext.
- **`Client::Rooms`**, mixed into `Client` — the room action surface, all
  keyword arguments and all routed through `#api` so a typo is an
  `InvalidEndpointError` rather than a 404: `#invite`, `#kick`, `#ban`,
  `#unban`, `#forget_room`, `#joined_members`, `#joined_rooms`, `#create_room`,
  `#send_event`, `#redact`, `#messages`, `#event`, `#send_state`, `#get_state`,
  `#room_state`, `#set_room_name`, `#set_room_topic`, `#set_pinned_events`,
  `#set_power_level`, `#read_receipt`, `#typing`, `#account_data`,
  `#set_account_data` and `#room_account_data`. Nothing here encrypts;
  `#send_event` sends exactly the content it is given.
- **`Async::Matrix::AppServiceClient`** — a `Client` that acts *as* one of the
  appservice's users on one of their devices, via the merged `?user_id=`
  ([MSC4326](https://github.com/matrix-org/matrix-spec-proposals/pull/4326)) and MSC4190 device creation rather than the `/login` route that
  OAuth2-fronted homeservers answer `M_APPSERVICE_LOGIN_UNSUPPORTED` to. No
  per-user token is issued, so none can expire. `#as(user_id:, device_id:)` and
  `#with_device(device_id)` return sibling clients sharing the config and retry
  policy, which is what keeps two fibers from racing over one client's
  identity.
- **`Async::Matrix::E2EE::PickleKey`** — the key every pickle in `E2EE` is
  encrypted with at rest. `.derive(secret, info:, salt:)` turns an application
  secret into the exact shape vodozemac accepts (32 characters of valid UTF-8,
  which is why 24 bytes of entropy are base64'd), and `#inspect` is redacted so
  the key cannot reach a log. Lose or rotate it and every pickle is
  permanently undecryptable.
- **`Client#default_query`** — query parameters added to every request this
  client makes. Empty on `Client`; `AppServiceClient` overrides it. A parameter
  the caller already set wins.
- **`Protocol::Matrix::Event#encrypted?`** (always `false`) and
  **`#decrypted?`** (always `true`), so a consumer reading a `MessageBatch`
  need not ask which class it is holding before reading `#type` and `#content`.

### Changed

- **`Async::Matrix::Event`, `Content`, `Schema`, `Schema::Registry` and
  `Schema::ValidationError` now live under `Protocol::Matrix`.** The old names
  are kept as aliases, so code written against 3.0 keeps working and
  `Schema.parse` still returns something `Async::Matrix::Event` matches; new
  code should name `Protocol::Matrix` directly.
- **`Async::Matrix::Error` is now a constant pointing at
  `Protocol::Matrix::Error`**, not a class of its own, so `rescue
  Async::Matrix::Error` catches a format failure and a transport failure alike
  and every existing subclass (`AuthError` and friends) still inherits it.
  The constructor now accepts a lone message — `raise MalformedError, "..."` —
  as well as the `(errcode, message, status:)` form the transport has always
  used. Anything matching on `Async::Matrix::Error.name` or comparing classes
  by identity across the two namespaces should stop doing so; they are one
  class.
- **`Client#join_room` and `#leave_room` accept `room_id:` as a keyword** as
  well as positionally, so they match the rest of the action surface. The
  positional form is unchanged.

### Fixed

- `DELETE` through `client.api` raised `NoMethodError`: `Api::Chain#execute`
  calls `Client#request`, which was private. It is now public.

## [3.0.0] - 2026-10-08

The Application Service layer has moved out of this gem into
[async-matrix-bridge](https://github.com/general-intelligence-systems/async-matrix-bridge).
async-matrix is now the Matrix *protocol* layer only: the Client-Server API
client, events and schema validation, media, and end-to-end encryption.

### Added

- **`Async::Matrix::Config`** — the config loading and `Vivify` dot-notation
  access that used to sit on `ApplicationService::Config`, minus the schema.
  It validates nothing; `.validate!` is a no-op class-method hook a subclass
  overrides to raise, which is the seam async-matrix-bridge uses to layer the
  bridgev2 JSON Schema suite back on. `Client` only ever read
  `homeserver.address` and `appservice.as_token`, so nothing in this gem needs
  the schema. `Config.load(path)` and `Config#bot_mxid` are unchanged; top-level
  sections remain an explicit `def_delegators` list, so a typo'd section still
  raises `NoMethodError` instead of autovivifying.

### Changed

- **`ApplicationService::Event` is now `Async::Matrix::Event`**, and
  `ApplicationService::Content` is `Async::Matrix::Content`. Neither was
  application-service-specific — `Schema.parse` returns one — and both are now
  in the namespace they describe, one constant per file.
- **`ApplicationService::ErrorResponse` is now `Async::Matrix::ErrorResponse`**,
  for the same reason: `Client` and `MediaClient` parse every failed response
  into one.
- Raised the minimum runtime dependencies to `async ~> 2.46`,
  `async-http ~> 0.105` and `json_schemer ~> 2.5`.
- The documentation site is now built with
  [just-the-docs](https://just-the-docs.com/) instead of utopia-project, at the
  same `documentation_uri`.

### Removed

- **`Async::Matrix::ApplicationService::*`** — `Server`, `Bot`, `Dispatcher`,
  `TransactionHandler`, `Transaction`, `TransactionStore`, and the bridgev2
  `Config` schema suite now live in async-matrix-bridge as
  `Async::Matrix::Bridge::ApplicationService::*`. Add that gem and
  `require "async/matrix/bridge"`; the class names are otherwise unchanged.
- **`Async::Matrix::Bridge::Discord` and `Async::Discord`** — the Discord
  bridge database layer and the Discord API/gateway client are gone, with no
  replacement. This drops the `sequel`, `async-websocket` and `sqlite3`
  dependencies.
- **`grape`** is no longer a dependency; it belongs to the application service,
  and so now to async-matrix-bridge. `falcon` is likewise no longer a
  development dependency.
- **`Config.schema` and `Config::SCHEMA_DIR`**, with the bundled bridgev2 JSON
  Schema files. `Config.validate!` is now a no-op, so `Config.new` no longer
  raises `BadJsonError` for a config that fails the schema, and no longer
  inserts the schema's property defaults into the data. Subclass `Config` and
  override `.validate!` — or use async-matrix-bridge's `Config` — if you want
  either back.
- `bin/fetch-discord-api-spec`, and `examples/` (which are all application
  services — they moved to async-matrix-bridge too).

### Fixed

- `lib/async/matrix.rb` no longer calls `require "bundler/setup"`. A library
  has no business activating the host application's bundle, and doing so broke
  any application whose own `Gemfile` did not already match.

### Security

- Dropping `grape` removes `activesupport` and with it `concurrent-ruby` from
  the dependency tree entirely, which closes GHSA-h8w8-99g7-qmvj (plus two low
  advisories) for this gem. The transitive pin had already been bumped to
  `concurrent-ruby 1.3.7` before the dependency was removed.

## [2.1.0] - 2026-08-01

Megolm room keys can now be imported from key backup and from forwarded
sessions, and exported for the same.

### Added

- `InboundGroupSession.import(exported_key)` — build a session from a base64
  **exported** session key. Server-side key backup
  (`m.megolm_backup.v1.curve25519-aes-sha2`) and `m.forwarded_room_key` both
  carry an `ExportedSessionKey`, which is version 1 and carries no signature,
  while `InboundGroupSession.new` requires a signed version-2 `SessionKey` and
  rejects them outright. Without `import`, a client can never read history it
  did not receive a live `m.room_key` for.
- `InboundGroupSession#export_at(index)` and
  `InboundGroupSession#export_at_first_known_index` — export a session in that
  same format, for uploading to key backup or forwarding to another device.
  `export_at` returns `nil` once the ratchet has advanced past `index`; megolm
  ratchets forward only, so earlier indices are unrecoverable by design.

Sessions built with `import` are not signature-verified, because an exported
key has no signature to verify. That is inherent to the format — the spec
likewise treats backup-restored keys as unverified.

## [2.0.1] - 2026-07-09

Packaging release: `gem install async-matrix` no longer requires a Rust
toolchain.

### Changed

- **Precompiled native gems.** The Rust/vodozemac E2EE extension is now
  cross-compiled into per-platform ("fat") gems via the rb-sys/oxidize-rb
  toolchain, so RubyGems serves users a prebuilt `.so` matching their platform
  instead of compiling from source at install time. Source compilation remains
  as a fallback for unsupported platforms.
- Switched the `Rakefile` from `Rake::ExtensionTask` to `RbSys::ExtensionTask`
  and added a workspace-root `Cargo.toml`/`Cargo.lock` (the lockfile moved out
  of `ext/`), which the cross-compilation toolchain resolves from.
- `e2ee.rb` now loads the compiled object from the per-Ruby-version subdirectory
  used by fat gems, falling back to the flat path for local source builds.
- Added a CI workflow that cross-compiles the platform gems on push to `main`
  and uploads them as build artifacts (publishing remains a manual step).

## [2.0.0] - 2026-07-09

Major release. The Application Service server has been rebuilt on
[Grape](https://github.com/ruby-grape/grape), and transaction handling has been
extracted into a dedicated, long-lived object. These are breaking changes to the
server-side API.

### Changed

- **Grape-based Application Service server.** `ApplicationService::Server` now
  wraps a `Grape::API` instead of a hand-rolled Rack app. It forwards the Grape
  route DSL, so application-specific endpoints can be declared alongside the
  Matrix wire-protocol routes. Adds a runtime dependency on `grape ~> 3.3`.
- **Event registration via `#dispatch`.** Handlers and bots are now attached
  with the `dispatch { on "m.room.message" do |event| … end }` DSL on the
  server, replacing the previous `#register` flow.
- **`TransactionHandler` introduced.** Idempotent transaction processing and
  handler routing now live in `ApplicationService::TransactionHandler`, a stable
  long-lived object, rather than in the stateless HTTP layer. The Bot/handler
  duck-type (`#event_types`, `#call`) is unchanged.
- **`scampi` is now a development dependency** (bumped to `~> 1.0`) instead of a
  runtime dependency. Inline co-located tests moved to `__END__` sections.
- Reworked the dispatcher and transaction store around the new
  `TransactionHandler`.
- Query parameters are now supported on all HTTP client methods.
- Updated all bundled examples (`echo_bot`, `brute`, `brute-steering`,
  `lindsey_and_dave`, `inbound_webhook_bot`) to the new server API; dropped the
  checked-in `Gemfile.lock` files in favour of a shared test harness
  (`examples/run_test.sh`).
- Improved event logging.

## [1.2.1] - 2026-06-08

### Fixed

- Fixed the Ruby 4.0 build by bumping the native `magnus` binding from 0.7 to
  0.8.

## [1.2.0] - 2026-06-08

### Added

- Added end-to-end encryption (Olm/Megolm) via a native `vodozemac` binding.

## [1.0.0] - 2026-04-28

### Added

- First release: async-native Matrix Application Service SDK built on the
  Socketry ecosystem, with schema-driven event validation, an OpenAPI-backed
  client, media support, and mautrix-compatible configuration.

[Unreleased]: https://github.com/general-intelligence-systems/async-matrix/compare/v3.0.1...HEAD
[3.0.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v3.0.1
[3.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v3.0.0
[2.1.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.1.0
[2.0.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.0.1
[2.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.0.0
[1.2.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.1
[1.2.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.0
[1.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.0.0
