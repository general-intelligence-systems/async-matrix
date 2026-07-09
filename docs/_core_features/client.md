---
layout: default
title: Client
nav_order: 3
description: The fiber-safe HTTP client — convenience methods, the schema-validated API chain, retries and backoff, and media.
---

# Client

`Async::Matrix::Client` is how your service talks *back* to the homeserver. It wraps `Async::HTTP::Internet` — fiber-safe, with automatic connection pooling — and authenticates every request with the `as_token` from your [config]({% link _advanced/configuration.md %}).

```ruby
client = Async::Matrix::Client.new(config)
```

## Convenience methods

The common actions have direct methods:

```ruby
client.send_text(room_id, "Hello world")
client.send_html(room_id, "<b>bold</b>")          # optional 3rd arg: plaintext fallback
client.send_notice(room_id, "Bot says hi")
client.join_room(room_id)
client.leave_room(room_id)
client.set_display_name("My Bot")                 # optional 2nd arg: user_id
client.whoami
```

For arbitrary message events there's `send_message_event(room_id, event_type, content)`.

## The API chain

Anything beyond the convenience methods goes through `client.api`, a method-chained interface to the **full** Matrix Client-Server API. Each chained segment becomes a path component; the terminal `.get/.post/.put/.delete` dispatches the request. The path is validated at runtime against the official OpenAPI documents bundled in the gem, so a typo'd endpoint fails fast rather than hitting the homeserver:

```ruby
client.api.createRoom.post(name: "Pub")
client.api.rooms("!room:ex.com").messages.get(dir: "b", limit: 10)
client.api.rooms(room_id).read_markers.post("m.fully_read" => event_id)
```

Path parameters are passed as call arguments (`rooms("!room:ex.com")`); query parameters and JSON bodies are passed to the terminal verb as keyword/hash arguments. Because the chain is built on `BasicObject`, even method-like segment names (`send`, `display`, `format`) route through the chain rather than colliding with Ruby's own methods.

{: .note }
Binary routes — media upload, download, thumbnails — are detected from the path and dispatched through the [`MediaClient`](#media) instead of the JSON client. Media endpoints that the spec pins to `/v1` are rewritten automatically even if you chain them under `/v3`.

## Low-level requests

If you need to bypass the chain entirely, the verb methods take a raw path:

```ruby
client.get("/_matrix/client/v3/account/whoami")
client.put("/_matrix/client/v3/rooms/#{room_id}/send/m.room.message/#{txn}", body)
client.post(path, body, max_retries: 5)
```

## Retries, backoff, and limits

The client hardens every request against a flaky or rate-limiting homeserver:

- **Retryable statuses.** `502`, `503`, `504` are always retried; `429` is retried unless rate-limit handling is disabled. Up to `DEFAULT_MAX_RETRIES` (3) attempts; pass `max_retries:` per call to override (0 disables).
- **Gateway errors** use exponential backoff with **full jitter** (`rand(0..delay)`, the AWS-recommended strategy) to avoid retry stampedes.
- **Rate limits** honor the server's `Retry-After` header — both delta-seconds (`120`) and HTTP-date forms — falling back to exponential backoff when it's absent.
- **Response-size limiting.** JSON responses are capped (50 MiB) and error bodies more tightly, enforced while streaming so an oversized body is cut off rather than buffered whole.

## Media

`client.media` returns a `MediaClient` for binary transfers (also reachable via the API chain's binary routes):

```ruby
mxc = client.media.upload(:post, upload_path, bytes, "image/png")
data = client.media.download(download_path)
```

Uploads take an explicit content type (default `application/octet-stream`); downloads stream with the same size-limit enforcement as the JSON client. See [Media]({% link _advanced/media.md %}) for the full flow.

## Lifecycle

Everything is fiber-safe and pools connections, so share one `Client` across all handlers — do **not** create one per event. Call `client.close` on shutdown to drain the pool.
