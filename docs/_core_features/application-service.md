---
layout: default
title: Application Service
nav_order: 1
description: The Grape-based Application Service server, its Matrix wire-protocol routes, authentication, idempotency, and the transaction dispatch flow.
---

# Application Service

`ApplicationService::Server` is the server side of the [Matrix Application Service API](https://spec.matrix.org/latest/application-service-api/). It wraps a [Grape](https://github.com/ruby-grape/grape) `API` with the Matrix wire-protocol routes mixed in, and it is itself a Rack app — `run server` works directly, and it mounts into any larger Rack stack.

## Constructing a server

```ruby
app = Async::Matrix::ApplicationService::Server.new(
  hs_token: config.appservice.hs_token,   # authenticates inbound transactions
  client:   client                        # optional; exposed to your own endpoints
) do
  dispatch some_bot_or_handler
end
```

The block is evaluated in the server's context. Because the server forwards Grape's route DSL, you can declare application-specific endpoints right alongside the Matrix routes — they are *not* subject to Matrix's `hs_token` auth, so guard them yourself:

```ruby
Async::Matrix::ApplicationService::Server.new(hs_token:, client:) do
  dispatch bot

  post "/_webhook/send" do
    client.send_text(params[:room_id], params[:body])
    { ok: true }
  end
end
```

## Routes

Mixing the protocol in defines these routes, all under `/_matrix/app/v1`:

| Method & path | Purpose | Auth |
|---|---|---|
| `PUT transactions/{txnId}` | receive a batch of events | yes |
| `POST ping` | homeserver healthcheck | no |
| `GET users/{userId}` | user-existence query | yes |
| `GET rooms/{roomAlias}` | room-alias query | yes |
| `GET thirdparty/protocol/{proto}` | protocol metadata | yes |
| `GET thirdparty/location(/{proto})` | location lookup | yes |
| `GET thirdparty/user(/{proto})` | user lookup | yes |

Third-party queries delegate to an optional `thirdparty:` collaborator — a duck-type with `protocol(name)`, `locations(proto, params)`, and `users(proto, params)`. Return `nil` from `protocol` to produce a `404 M_NOT_FOUND`.

## The event flow

```
homeserver PUT transaction
        │
        ▼
authenticate!            constant-time compare on hs_token → 403 M_FORBIDDEN on mismatch
        │
        ▼
TransactionStore         seen this txnId? → 200 immediately (idempotent, no re-dispatch)
        │
        ▼
TransactionHandler       route each event to handlers whose #event_types match
        │
        ▼
your handlers            run independently; one raising is logged, the rest still run
```

Two properties matter for correctness against a real homeserver:

- **Constant-time authentication.** The `hs_token` is compared with a length-safe, constant-time routine so a mismatch leaks no timing signal.
- **Idempotency.** Homeservers retry transactions they didn't get a `200` for. The `TransactionStore` is an in-memory LRU (capacity 1024, prunes the oldest half when full) keyed by transaction ID, so a retried batch is acknowledged without running your handlers twice. Because the HTTP layer is stateless across requests, this store lives on the long-lived `TransactionHandler`, not on the request.

## TransactionHandler

`ApplicationService::TransactionHandler` is the stable object that owns handler registration and idempotent dispatch. `Server#dispatch` delegates to it, and `server.dispatcher` exposes it (e.g. `server.dispatcher.handler_count`). You can also use it standalone if you are mixing the routes into your own Grape API:

```ruby
class MyAppService < Grape::API
  include Async::Matrix::ApplicationService::Server::Grape
end

handler = Async::Matrix::ApplicationService::TransactionHandler.new
handler.register(bot)

MyAppService.configure do |c|
  c[:hs_token]    = config.appservice.hs_token
  c[:dispatcher]  = handler
  c[:client]      = client
end
```

`register` accepts a `Bot` (expanded into its handlers) or any object satisfying the [handler duck-type]({% link _core_features/bots-and-handlers.md %}).

## Serving

`Server` delegates `#call(env)` to the wrapped Grape API, so any async-capable Rack server runs it. In production, use [Falcon](https://github.com/socketry/falcon):

```sh
falcon serve --bind http://0.0.0.0:9292
```

Falcon runs each request on a fiber, which is what lets a single process fan out thousands of concurrent homeserver calls from inside your handlers without threads.
