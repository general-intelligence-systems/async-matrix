# Changelog

All notable changes to **async-matrix** are documented here. The format is
loosely based on [Keep a Changelog](https://keepachangelog.com/), and this
project adheres to [Semantic Versioning](https://semver.org/).

## [2.0.0] - 2026-07-09

Major release. The Application Service server has been rebuilt on
[Grape](https://github.com/ruby-grape/grape), and transaction handling has been
extracted into a dedicated, long-lived object. These are breaking changes to the
server-side API.

### Breaking changes

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

### Changed

- Reworked the dispatcher and transaction store around the new
  `TransactionHandler`.
- Query parameters are now supported on all HTTP client methods.
- Updated all bundled examples (`echo_bot`, `brute`, `brute-steering`,
  `lindsey_and_dave`, `inbound_webhook_bot`) to the new server API; dropped the
  checked-in `Gemfile.lock` files in favour of a shared test harness
  (`examples/run_test.sh`).
- Improved event logging.

## [1.2.1] - 2026

- Fixed the Ruby 4.0 build by bumping the native `magnus` binding from 0.7 to
  0.8.

## [1.2.0] - 2026

- Added end-to-end encryption (Olm/Megolm) via a native `vodozemac` binding.

## [1.0.0] - 2026

- First release: async-native Matrix Application Service SDK built on the
  Socketry ecosystem, with schema-driven event validation, an OpenAPI-backed
  client, media support, and mautrix-compatible configuration.

[2.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v2.0.0
[1.2.1]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.1
[1.2.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.2.0
[1.0.0]: https://github.com/general-intelligence-systems/async-matrix/releases/tag/v1.0.0
