# Echo Bot Demo

A complete local development stack running an echo bot appservice against a Synapse homeserver, with FluffyChat as the web client.

## Services

| Service | Description | URL |
|---------|-------------|-----|
| Synapse | Matrix homeserver | `https://localhost` (via proxy) |
| Bot | Echo bot appservice | `localhost:9292` (internal) |
| FluffyChat | Matrix web client | `https://localhost` |
| Proxy | nginx reverse proxy (HTTPS) | `https://localhost` |

## Quick Start

```bash
docker compose up -d
```

First run will pull images and build the bot (~2 minutes). Subsequent starts are fast.

## Register a Test User

```bash
docker compose exec synapse register_new_matrix_user \
  -u testuser -p testpass -a \
  -c /data/homeserver.yaml http://localhost:8008
```

## Log In with FluffyChat

1. Open **https://localhost** in your browser
2. Accept the self-signed certificate warning
3. On the login screen, enter `localhost` in the homeserver address field
4. Sign in with:
   - **Username:** `testuser`
   - **Password:** `testpass`

## Test the Echo Bot

1. Create a new room (tap the `+` button)
2. Invite `@bot:localhost` to the room
3. Send any text message
4. The bot auto-joins and echoes your message back as a notice prefixed with `Echo:`

## Watch Bot Logs

```bash
docker compose logs -f bot
```

## Architecture

```
Browser (https://localhost)
    │
    ▼
┌─────────┐
│  nginx  │ :443 (HTTPS, self-signed)
└────┬────┘
     │
     ├── /              → FluffyChat (static web app)
     ├── /_matrix       → Synapse :8008
     └── /.well-known   → Synapse :8008
                              │
                              │ pushes transactions to
                              ▼
                         Bot :9292
                              │
                              │ sends messages via
                              ▼
                         Synapse :8008
```

## Stopping

```bash
docker compose down
```

## Notes

- The self-signed TLS certificate lives in `certs/` and is required because Matrix clients enforce HTTPS for homeserver discovery.
- The bot's appservice registration is pre-configured in `files/appservices/registration.yml`.
- Synapse data (SQLite DB, media, keys) persists in `files/`.
- To reset everything: `docker compose down -v && rm -rf files/homeserver.db*`
