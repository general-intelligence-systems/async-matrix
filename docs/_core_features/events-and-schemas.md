---
layout: default
title: Events & Schemas
nav_order: 4
description: The Event wrapper and schema-driven validation against the official Matrix event JSON schemas.
---

# Events & Schemas

Every event delivered to a handler is an `ApplicationService::Event` wrapping the raw Matrix JSON. It gives you typed accessors and, when you want it, validation against the official Matrix event schemas.

## The Event object

```ruby
on "m.room.message" do |event|
  event.type        # "m.room.message"
  event.sender      # "@alice:example.com"
  event.room_id     # "!abc:example.com"
  event.event_id    # "$..."
  event.state_key   # nil for message events; "" or an MXID for state events
  event.state_event?  # true when state_key is present
  event.content     # dot-accessible content wrapper
end
```

`content` is itself accessor-friendly and nil-safe. Message-shaped content exposes `msgtype`, `body`, and `membership` directly; anything else falls through `method_missing`, so `event.content.info&.mimetype` works for arbitrary fields. Use `&.` where a field may be absent:

```ruby
return unless event.content&.msgtype == "m.text"
send_notice event.room_id, "Echo: #{event.content.body}"
```

`event.to_h` returns the raw hash if you need the untouched JSON.

## Validation

Events validate against the upstream [matrix-org/matrix-spec](https://github.com/matrix-org/matrix-spec) event JSON schemas, bundled into the gem. Validation is opt-in — dispatch does not reject invalid events for you, so call it where you care:

```ruby
event.valid?   # => true / false
event.valid!   # => raises Schema::ValidationError on failure
```

`valid!` raises a `Schema::ValidationError` carrying the failing event type, event ID, and human-readable key paths to each violation — useful in logs when a bridge produces malformed events.

## The Schema module

`Async::Matrix::Schema` is the validation entry point, backed by a lazily-loaded singleton `Registry`:

```ruby
Async::Matrix::Schema.valid?(event_hash)     # => true / false
Async::Matrix::Schema.validate(event_hash)   # => Array<Hash> of errors (empty if valid)
Async::Matrix::Schema.content_properties("m.room.message")  # declared content fields
```

### Base and variant schemas

Some event types have variants keyed on a discriminator — `m.room.message` splits by `msgtype`, for example. These are stored with a filename convention that joins base and subtype on `$` (`m.room.message$m.text`), and resolved automatically when the event carries the discriminator. `Schema.variant(type, subtype)` selects one explicitly.

### Custom formats

The validator registers Matrix-specific string formats on top of standard JSON Schema, so identifier fields are checked for real:

`mx-user-id` · `mx-room-id` · `mx-room-alias` · `mx-event-id` · `mx-server-name` · `mx-unpadded-base64`

Schemas load on first use and stay cached for the process lifetime, so validation is cheap after the first touch and always matches the spec revision vendored in `data/`.
