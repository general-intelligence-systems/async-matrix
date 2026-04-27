# async-matrix

[![Gem Version](https://img.shields.io/gem/v/async-matrix)](https://rubygems.org/gems/async-matrix)
[![CI](https://github.com/general-intelligence-systems/async-matrix/actions/workflows/test.yaml/badge.svg)](https://github.com/general-intelligence-systems/async-matrix/actions/workflows/test.yaml)
[![License](https://img.shields.io/github/license/general-intelligence-systems/async-matrix)](https://github.com/general-intelligence-systems/async-matrix/blob/main/LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-red)](https://www.ruby-lang.org)

Async-native [Matrix](https://matrix.org) Application Service SDK for Ruby. Built on the [Socketry](https://github.com/socketry) ecosystem (`async`, `async-http`, Falcon). No threads, no callbacks -- just fibers.

## Install

```ruby
gem "async-matrix"
```

## Echo Bot in 25 Lines

```ruby
# config.ru
require "async/matrix"

config     = Async::Matrix::ApplicationService::Config.load("config/appservice.yml")
client     = Async::Matrix::Client.new(config)
dispatcher = Async::Matrix::ApplicationService::Dispatcher.new

# Auto-join when invited
invite = Object.new
invite.define_singleton_method(:event_types) { ["m.room.member"] }
invite.define_singleton_method(:call) { |event|
  next unless event.content&.membership == "invite"
  next unless event.state_key == client.config.bot_mxid
  client.join_room(event.room_id)
}

# Echo messages back as notices
echo = Object.new
echo.define_singleton_method(:event_types) { ["m.room.message"] }
echo.define_singleton_method(:call) { |event|
  next unless event.content&.msgtype == "m.text"
  next unless event.sender != client.config.bot_mxid
  client.send_notice(event.room_id, "Echo: #{event.content.body}")
}

dispatcher.register(invite)
dispatcher.register(echo)

run Async::Matrix::ApplicationService::Server.new(
  hs_token: config.hs_token, dispatcher: dispatcher
)
```

```sh
falcon serve --bind http://0.0.0.0:9292
```

## Handlers

Any object that responds to `#event_types` and `#call(event)`. That's it.

```ruby
class Invite
  def initialize(client) = @client = client

  def event_types = ["m.room.member"]

  def call(event)
    return unless event.content&.membership == "invite"
    return unless event.state_key == @client.config.bot_mxid
    @client.join_room(event.room_id)
  end
end
```

```ruby
class Message
  def initialize(client) = @client = client

  def event_types = ["m.room.message"]

  def call(event)
    return unless event.content&.msgtype == "m.text"
    return unless event.sender != @client.config.bot_mxid
    @client.send_notice(event.room_id, "Echo: #{event.content.body}")
  end
end
```

Register them:

```ruby
dispatcher = Async::Matrix::ApplicationService::Dispatcher.new
dispatcher.register(Invite.new(client))
dispatcher.register(Message.new(client))
```

Fault-tolerant -- one handler blowing up won't take down the rest.

## Client API

```ruby
client = Async::Matrix::Client.new(config)

client.send_text(room_id, "Hello world")
client.send_html(room_id, "<b>bold</b>")
client.send_notice(room_id, "Bot says hi")
client.join_room(room_id)
client.leave_room(room_id)
client.set_display_name("My Bot")
client.whoami  # => {"user_id" => "@bot:example.com"}
```

All methods are fiber-safe with automatic connection pooling via `Async::HTTP::Internet`.

## Well-Known Discovery

```ruby
Async do
  endpoint = Async::Matrix::Endpoint.discover("example.com")
  # Resolves /.well-known/matrix/client, falls back to https://example.com
end
```

## Configuration

### `appservice.yml` -- runtime config

```yaml
homeserver:
  url: "http://synapse:8008"
  domain: "localhost"

appservice:
  as_token: "your-appservice-token"
  hs_token: "your-homeserver-token"
  bot_mxid: "@bot:localhost"

server:
  bind: "http://0.0.0.0:9292"
```

### `registration.yml` -- give this to your homeserver admin

```yaml
id: ruby-bot
url: "http://bot:9292"
as_token: "your-appservice-token"  # must match appservice.yml
hs_token: "your-homeserver-token"  # must match appservice.yml
sender_localpart: bot
namespaces:
  users:
    - exclusive: false
      regex: "@bot:localhost"
  rooms: []
  aliases: []
rate_limited: false
push_ephemeral: false
```

Override the config path with `APPSERVICE_CONFIG`:

```sh
APPSERVICE_CONFIG=/etc/bot/appservice.yml falcon serve
```

## Architecture

```
Synapse ──PUT /transactions/{txnId}──▶ Server (Rack 3)
                                          │
                                     Dispatcher
                                      ┌───┴───┐
                                  Handler   Handler
                                      │
                              Client ──PUT /rooms/.../send──▶ Synapse
```

- **Server** authenticates the `hs_token` (timing-safe), deduplicates transactions
- **Dispatcher** routes events by type, catches handler errors
- **Client** authenticates with `as_token`, pools connections

## Running with Docker

A complete echo bot example lives in [`examples/echo_bot/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/echo_bot) with Docker Compose, Synapse, and nginx.

```sh
cd examples/echo_bot
docker compose up -d --build
```

## Testing

Tests are inline via [Scampi](https://rubygems.org/gems/scampi) -- co-located with the code they test.

```sh
bundle exec scampi
```

## Guides

- [Matrix Events Reference](https://general-intelligence-systems.github.io/async-matrix/matrix-events/) -- auto-generated documentation for every Matrix event type

## License

Apache 2.0
