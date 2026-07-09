---
layout: default
title: Bots & Handlers
nav_order: 2
description: The Bot DSL, its event filters and context helpers, and the plain handler duck-type for full control.
---

# Bots & Handlers

Everything you register with `dispatch` is a *handler*: any object that responds to `#event_types -> Array<String>` and `#call(event)`. There are two ways to produce one — the `Bot` DSL for the common case, and plain objects when you want full control.

## The Bot DSL

`Bot.new(client) { ... }` pairs a [`Client`]({% link _core_features/client.md %}) with handler blocks declared via `on`:

```ruby
bot = Async::Matrix::ApplicationService::Bot.new(client) do
  on "m.room.member" do |event|
    join_room(event.room_id) if event.content.membership == "invite"
  end

  on "m.room.message", msgtype: "m.text", not_from: :self do |event|
    send_notice event.room_id, "Echo: #{event.content.body}"
  end
end
```

A `Bot` responds to `#handlers`, so `dispatch bot` (or `handler.register bot`) expands it into its individual handlers.

### `on(*event_types, msgtype:, not_from:, &block)`

Register a block for one or more event types. Both filters are optional:

- **`msgtype:`** — only dispatch when `event.content.msgtype` matches (e.g. `"m.text"`). Events with a different msgtype are skipped before your block runs.
- **`not_from:`** — pass `:self` to skip events sent by this bot's own MXID. Essential for avoiding echo loops.

You can pass several event types to one block:

```ruby
on "m.room.message", "m.room.encrypted" do |event|
  # ...
end
```

### Context helpers

Handler blocks execute in a `Context` bound to the client, so they can call these directly without touching the client:

| Helper | Delegates to |
|---|---|
| `send_text(room_id, text)` | plain text message |
| `send_html(room_id, html, plaintext = nil)` | formatted message |
| `send_notice(room_id, text)` | `m.notice` message |
| `join_room(room_id)` | join |
| `leave_room(room_id)` | leave |
| `set_display_name(name, user_id = nil)` | profile update |
| `client` | the underlying `Client`, for anything else |

Reach for `client` when you need an API call the context doesn't wrap:

```ruby
on "m.room.message" do |event|
  client.api.rooms(event.room_id).read_markers.post("m.fully_read" => event.event_id)
end
```

## Plain handlers

When you want more structure than a block — state, injected collaborators, unit tests — implement the duck-type directly. This is exactly what a `Bot` produces under the hood.

```ruby
class Echo
  def initialize(client) = @client = client

  def event_types = ["m.room.message"]

  def call(event)
    return unless event.content&.msgtype == "m.text"
    return if event.sender == @client.config.bot_mxid

    @client.send_notice(event.room_id, "Echo: #{event.content.body}")
  end
end

dispatch Echo.new(client)
```

A handler is registered under each type in its `#event_types`; an event is delivered to every handler that matches its type.

## Fault tolerance

Dispatch is deliberately fault-tolerant: an exception raised in one handler is caught and logged, and the remaining handlers for that event still run. A single misbehaving handler cannot stop the homeserver's transaction from being acknowledged, nor block its siblings. Handle expected failures inside your own `call` where you want specific recovery; rely on the dispatcher only as a backstop.

## Events

The `event` yielded to a handler wraps the raw Matrix event JSON with convenient accessors — `event.room_id`, `event.sender`, `event.type`, `event.state_key`, `event.event_id`, and `event.content` (itself dot-accessible, e.g. `event.content.body`, `event.content.membership`). Content access is nil-safe with `&.` where a field may be absent. See [Events & Schemas]({% link _core_features/events-and-schemas.md %}) for validation.
