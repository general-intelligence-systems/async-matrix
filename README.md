# async-matrix

[![Ask DeepWiki](https://deepwiki.com/badge.svg)](https://deepwiki.com/general-intelligence-systems/async-matrix)

[![Gem Version](https://img.shields.io/gem/v/async-matrix)](https://rubygems.org/gems/async-matrix)
[![CI](https://github.com/general-intelligence-systems/async-matrix/actions/workflows/test.yaml/badge.svg)](https://github.com/general-intelligence-systems/async-matrix/actions/workflows/test.yaml)
[![License](https://img.shields.io/github/license/general-intelligence-systems/async-matrix)](https://github.com/general-intelligence-systems/async-matrix/blob/main/LICENSE)
[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.3-red)](https://www.ruby-lang.org)

Async-native [Matrix](https://matrix.org) Application Service SDK for Ruby. Built on the [Socketry](https://github.com/socketry) ecosystem (`async`, `async-http`, Falcon). No threads, no callbacks -- just fibers.

## Usage

Please see the [project documentation](https://general-intelligence-systems.github.io/async-matrix/) for more details.

## Install

```ruby
gem "async-matrix"
```

## Quick Start

```ruby
# config.ru
require "async/matrix"

config = Async::Matrix::ApplicationService::Config.load("config/appservice.yml")
client = Async::Matrix::Client.new(config)

bot = Async::Matrix::ApplicationService::Bot.new(client) do
  on "m.room.member" do |event|
    join_room(event.room_id) if event.content.membership == "invite"
  end

  on "m.room.message", msgtype: "m.text", not_from: :self do |event|
    send_notice event.room_id, "Echo: #{event.content.body}"
  end
end

app = Async::Matrix::ApplicationService::Server.new(
  hs_token: config.appservice.hs_token,
  client:   client
) do
  dispatch bot
end

run app
```

```bash
falcon serve --bind http://0.0.0.0:9292
```

A complete working example with Docker Compose and Synapse lives in [`examples/echo_bot/`](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/echo_bot).

## Handlers

Any object that responds to `#event_types` and `#call(event)` is a handler. Use this when you need more control than the Bot DSL provides.

```ruby
class Echo
  def initialize(client) = @client = client

  def event_types = ["m.room.message"]

  def call(event)
    return unless event.content&.msgtype == "m.text"
    return unless event.sender != @client.config.bot_mxid
    @client.send_notice(event.room_id, "Echo: #{event.content.body}")
  end
end

app.dispatch(Echo.new(client))
```

Dispatch is fault-tolerant -- one handler raising won't take down the rest.

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

All methods are fiber-safe with automatic connection pooling.

## Configuration

Create `config/appservice.yml` for your bot:

```yaml
homeserver:
  address: "http://synapse:8008"
  domain: "localhost"

appservice:
  as_token: "your-appservice-token"
  hs_token: "your-homeserver-token"
  bot:
    username: "bot"
```

You'll also need a [`registration.yml`](https://spec.matrix.org/latest/application-service-api/#registration) registered with your homeserver. See the [echo bot example](https://github.com/general-intelligence-systems/async-matrix/tree/main/examples/echo_bot) for a working template.

Override the config path at runtime:

```bash
APPSERVICE_CONFIG=/etc/bot/appservice.yml falcon serve
```

## Built With

- [async](https://github.com/socketry/async) -- fiber-based concurrency framework
- [async-http](https://github.com/socketry/async-http) -- HTTP client/server with connection pooling
- [falcon](https://github.com/socketry/falcon) -- async Rack-compatible web server
- [json_schemer](https://github.com/davishmcclurg/json_schemer) -- JSON Schema validation
- [scampi](https://github.com/general-intelligence-systems/scampi) -- inline co-located test framework
- [string_builder](https://github.com/general-intelligence-systems/string_builder) -- method-chain string builder

## License

Apache 2.0
