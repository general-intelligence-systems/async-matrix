# Synapse Development Stack

A local development stack providing a Synapse homeserver with FluffyChat as the web client, fronted by an nginx reverse proxy with self-signed HTTPS.

This directory provides the **infrastructure only**. To run an appservice bot against it, see [`examples/echo_bot/`](../echo_bot/).

## Services

| Service | Description | URL |
|---------|-------------|-----|
| Synapse | Matrix homeserver | `https://localhost` (via proxy) |
| FluffyChat | Matrix web client | `https://localhost` |
| Proxy | nginx reverse proxy (HTTPS) | `https://localhost` |

## Quick Start (with Echo Bot)

From the `examples/echo_bot/` directory:

```bash
cd examples/echo_bot
docker compose up -d
```

This uses Docker Compose `include` to pull in the Synapse stack defined here, plus the echo bot service.

## Quick Start (infrastructure only)

```bash
cd examples/synapse
docker compose up -d
```

This starts Synapse, FluffyChat, and the proxy without any bot.

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

## Architecture

```
Browser (https://localhost)
    |
    v
+---------+
|  nginx  | :443 (HTTPS, self-signed)
+----+----+
     |
     +-- /              -> FluffyChat (static web app)
     +-- /_matrix       -> Synapse :8008
     +-- /.well-known   -> Synapse :8008
                              |
                              | pushes transactions to
                              v
                         Bot :9292 (from echo_bot/)
                              |
                              | sends messages via
                              v
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
