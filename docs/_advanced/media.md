---
layout: default
title: Media
nav_order: 3
description: Uploading and downloading binary content through the MediaClient.
---

# Media

Matrix media (images, files, thumbnails) moves as raw bytes, not JSON. `Client` routes those transfers through a dedicated `MediaClient` so binary bodies never pass through JSON encoding. You reach it two ways — directly via `client.media`, or implicitly through the [API chain]({% link _core_features/client.md %}#the-api-chain), which detects binary routes and dispatches them to the media client automatically.

## Uploading

```ruby
bytes = File.binread("cat.png")
mxc   = client.media.upload(:post, upload_path, bytes, "image/png")
```

`upload(method, path, body, content_type = "application/octet-stream")` sends the bytes with an explicit content type and returns the homeserver's response (the `mxc://` URI you then reference in a message event). Pass the correct content type — it's what clients use to render the file.

## Downloading

```ruby
data = client.media.download(download_path)
```

`download(path)` streams the body back with the same **size-limit enforcement** the JSON client applies, so a hostile or misconfigured homeserver can't make you buffer an unbounded response — an oversized body is cut off mid-stream rather than read whole.

## Version rewriting

The Matrix media endpoints moved across spec versions. When you build a media path through the API chain at `/v3`, async-matrix rewrites it to `/v1` where the spec requires, so you can chain naturally without tracking which media route lives at which version.

## Config

Two config sections govern media behavior at the bridge level (see [Configuration]({% link _advanced/configuration.md %})):

- **`direct_media`** — serve media straight from the remote network rather than reuploading to your homeserver.
- **`public_media`** — expose media over a public, unauthenticated URL.

## Lifecycle

`MediaClient` uses the same fiber-safe, pooled `Async::HTTP::Internet` as the JSON client. Share it (via `client.media`) rather than constructing per transfer.
