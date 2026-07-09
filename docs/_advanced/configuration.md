---
layout: default
title: Configuration
nav_order: 1
description: JSON-Schema-validated appservice config, dot-notation access, and default vivification.
---

# Configuration

`ApplicationService::Config` loads your service's YAML config and validates it against a JSON-Schema suite before your bot ever starts — a missing token or a mistyped section fails at boot, not at the first homeserver call.

## Loading

```ruby
config = Async::Matrix::ApplicationService::Config.load("config/appservice.yml")
```

Or construct one from a hash directly (handy in examples and tests):

```ruby
config = Async::Matrix::ApplicationService::Config.new(
  "homeserver" => { "address" => "http://synapse:8008", "domain" => "localhost" },
  "appservice" => {
    "as_token" => "…",
    "hs_token" => "…",
    "bot"      => { "username" => "bot" },
  }
)
```

A minimal config:

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

Override the path at runtime without touching code:

```sh
APPSERVICE_CONFIG=/etc/bot/appservice.yml falcon serve
```

## Dot-notation access

The validated config is extended with the `Vivify` mixin, giving nested hashes dot-notation access with autovivification:

```ruby
config.homeserver.address          # => "http://synapse:8008"
config.appservice.bot.username     # => "bot"
config.bot_mxid                    # => "@bot:localhost"  (derived convenience)
```

`Vivify` is applied only to the config tree — it does not monkey-patch `Hash` globally. Reading an unset key vivifies an empty child rather than raising, so deep optional sections are safe to probe.

## Schema validation

Validation runs against a multi-file JSON-Schema suite under `application_service/config/schema/`, mirroring the [mautrix bridgev2](https://github.com/mautrix) Go config structs. The suite covers, among others:

`homeserver` · `appservice` · `bridge` · `database` · `encryption` · `double_puppet` · `direct_media` · `public_media` · `backfill` · `permissions` · `relay` · `provisioning` · `logging` · `analytics` · `management_room_texts`

Schemas are composed with `json_schemer` using `insert_property_defaults: true`, so any field with a schema default is **auto-filled** when absent — your YAML only needs to specify what differs from the defaults. Invalid config raises with the offending path, so typos surface immediately.
