# async-matrix

[![Gem Version](https://img.shields.io/gem/v/async-matrix)](https://rubygems.org/gems/async-matrix)
[![CI](https://github.com/general-intelligence-systems/async-matrix/actions/workflows/test.yaml/badge.svg)](https://github.com/general-intelligence-systems/async-matrix/actions/workflows/test.yaml)
[![License](https://img.shields.io/github/license/general-intelligence-systems/async-matrix)](https://github.com/general-intelligence-systems/async-matrix/blob/main/LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-red)](https://www.ruby-lang.org)

Async-native [Matrix](https://matrix.org) protocol primitives for Ruby. Built on the [Socketry](https://github.com/socketry) ecosystem (`async`, `async-http`, Falcon). No threads, no callbacks -- just fibers.

This gem is the protocol layer: a Client-Server API client, schema-validated events, media, and end-to-end encryption. The *server* side of a bridge or bot -- receiving transactions from a homeserver and dispatching events to handlers -- is [async-matrix-bridge](https://github.com/general-intelligence-systems/async-matrix-bridge), which builds on this gem.

## Usage

Please see the [project documentation](https://general-intelligence-systems.github.io/async-matrix/) for more details.

## Install

```ruby
gem "async-matrix"
```

## Quick Start

```ruby
require "async/matrix"

config = Async::Matrix::Config.load("config/appservice.yml")
client = Async::Matrix::Client.new(config)

Async do
  client.join_room("!room:example.org")
  client.send_notice("!room:example.org", "Hello from a fiber")
end
```

## Client

```ruby
client.send_text(room_id, "Hello world")
client.send_html(room_id, "<b>bold</b>")
client.send_notice(room_id, "Bot says hi")
client.join_room(room_id)
client.leave_room(room_id)
client.set_display_name("My Bot")
client.whoami
```

For anything beyond the convenience methods, `client.api` provides method-chained access to the full Matrix Client-Server API, validated at runtime against the official OpenAPI specs:

```ruby
client.api.createRoom.post(name: "Pub")
client.api.rooms("!room:ex.com").messages.get(dir: "b", limit: 10)
```

Binary routes (upload, download, thumbnail) are detected and dispatched to a dedicated `Client::Media`, so raw bytes never pass through JSON encoding.

All methods are fiber-safe with automatic connection pooling. The client retries 502/503/504 with exponential backoff and full jitter, honours `Retry-After` on 429, and caps response bodies while streaming them.

## Events

```ruby
event = Async::Matrix::Schema.parse(raw_hash)

event.type              # => "m.room.message"
event.sender            # => "@alice:example.org"
event.content.body      # => "hello"
event.valid?            # => true
event.valid!            # => true, or raises Schema::ValidationError
```

Events validate against the official Matrix event JSON schemas, bundled into the gem.

## Configuration

`Async::Matrix::Config` loads a YAML file (or a plain hash) and exposes it through dot notation. `Client` reads `homeserver.address` and `appservice.as_token`; it ignores the rest.

```yaml
# config/appservice.yml
homeserver:
  address: "http://synapse:8008"
  domain: "localhost"

appservice:
  as_token: "your-appservice-token"
  bot:
    username: "bot"
```

```ruby
config = Async::Matrix::Config.load("config/appservice.yml")
config.homeserver.address   # => "http://synapse:8008"
config.bot_mxid             # => "@bot:localhost"
```

It validates nothing by default. A subclass adds validation by overriding `.validate!` -- which is how async-matrix-bridge layers a mautrix bridgev2 JSON Schema suite on top without reimplementing the loading.

## Built With

- [async](https://github.com/socketry/async) -- fiber-based concurrency framework
- [async-http](https://github.com/socketry/async-http) -- HTTP client/server with connection pooling
- [json_schemer](https://github.com/davishmcclurg/json_schemer) -- JSON Schema validation
- [scampi](https://github.com/general-intelligence-systems/scampi) -- inline co-located test framework
- [string_builder](https://github.com/general-intelligence-systems/string_builder) -- method-chain string builder
- [vodozemac](https://github.com/matrix-org/vodozemac) -- Olm/Megolm, via a native Rust binding

## License

Apache 2.0
