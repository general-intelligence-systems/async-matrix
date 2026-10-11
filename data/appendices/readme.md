# Matrix specification appendices

The appendices of the Matrix specification, one copy per specification version.

This is **input you read, not output you produce**: each file is a copy of upstream at the commit this repository pins for that version, and the way to change one is to re-extract it.

## Why these files

Canonical JSON, signing JSON, unpadded Base64 and the cryptographic key representation live in the appendices rather than in any one API.

They are not E2EE material. Federation hashes and signs every event through Canonical JSON, the client-server event size limit is defined in terms of it, push rules match against its non-compound values, and room version 6 made enforcing it a room version rule. `lib/async/matrix/e2ee/canonical_json.rb` implements it, and `lib/async/matrix/server_key.rb` reaches across for it.

The generated `schemas/` describe the surface of each endpoint. The appendices describe the encoding every signature on that surface is computed over.

## Provenance

| | |
| --- | --- |
| Source | https://github.com/matrix-org/matrix-spec |
| Path | `content/appendices.md` |
| Extracted | 2026-10-12 |
| Licence | Apache License 2.0, the same as this project |

Copyright belongs to The Matrix.org Foundation C.I.C. and the contributors to the specification.

Each file is `content/appendices.md` at the commit `data/matrix-spec-<version>` points at, so a file here and its submodule agree by construction.

| Version | Commit | Lines | Against the previous version |
| --- | --- | --- | --- |
| `v1.1` | `43ce9127aeb4` | 1107 | — |
| `v1.2` | `fb2aa688db46` | 1249 | changed |
| `v1.3` | `b05149b64e1d` | 1249 | changed |
| `v1.4` | `7935a0728a12` | 1249 | unchanged |
| `v1.5` | `5f2fac89afdd` | 1249 | unchanged |
| `v1.6` | `029e9888359c` | 1249 | unchanged |
| `v1.7` | `8b51f1c01103` | 1286 | changed |
| `v1.8` | `529cbf4ffcf8` | 1304 | changed |
| `v1.9` | `0c099e3b7960` | 1304 | changed |
| `v1.10` | `4e51970c5571` | 1304 | unchanged |
| `v1.11` | `1fc8f8856fe4` | 1365 | changed |
| `v1.12` | `9e6233d0ddaf` | 1365 | unchanged |
| `v1.13` | `bc995e66d64b` | 1365 | changed |
| `v1.14` | `fe880fdaf4f7` | 1381 | changed |
| `v1.15` | `40065811a143` | 1381 | unchanged |
| `v1.16` | `81a864545f7d` | 1402 | changed |
| `v1.17` | `ce5ae4d37171` | 1402 | changed |
| `v1.18` | `c346686b0d20` | 1407 | changed |
| `v1.19` | `b9c3d5ed3b0b` | 1426 | changed |

An unchanged row is byte-identical to the version above it, so the version layer beside it has nothing to carry.

## Re-extracting

The submodules under `data/` are the source. With one checked out:

``` bash
git -C data/matrix-spec-v1.19 show HEAD:content/appendices.md > data/appendices/appendices-v1.19.md
```

Without checking any out, the same blobs come from a partial clone of upstream, read at each pinned commit.
