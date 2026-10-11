# AGENTS.md

## Hard rules

Do not run `bin/test --all` or every version in order. Only run the latest version with `bin/test`, unless expressly permitted.

Always run `bin/rubocop`.
DO NOT consider whether rubocop cops are intended... ABIDE by them as holey scripture and word of god.

The schemas are generated. Never edit a `.yaml` under a `schemas/` directory, and never run `bin/update-spec`, `bin/update-event-spec`, `bin/generate-spec-deltas` or `bin/generate-event-spec-deltas`. They are the input you read, not output you produce.

## The model

Everything is driven by the Matrix specification, version by version. `MATRIX_API_VERSIONS.txt` lists them: v1.1 to v1.19.

Each concept has three files:

| File | What it is |
| --- | --- |
| `lib/async/matrix/abstract/.../schemas/<name>-v1.N.yaml` | the surface at that version, generated from the spec |
| `lib/async/matrix/abstract/.../schemas/<name>-v1.N.deltas.yaml` | what v1.N changed against v1.(N-1) |
| `lib/async/matrix/abstract/.../<name>.rb` | one module per version, carrying what that version changed |
| `lib/async/matrix/{api,events}/.../<name>.rb` | the base class, carrying what every version has |

A deltas file with `changed: false` means the empty layer beside it is correct.

Read the code and its schema side by side: `rooms.rb` next to `schemas/rooms-v1.12.deltas.yaml`, and `module V1_12` implements that entry.

## Layering

`lib/async/matrix/versions.rb` builds the classes for a version: it takes the base class, then includes `V1_1`, `V1_2`, ... up to the version wanted, in ascending order.

So:

- Base class: supported from day one, or plumbing no version describes.
- `V1_N` layer: what v1.N added or changed. A later layer overrides an earlier one, and `super` walks back down.
- A method only exists at a version if its layer was included. That is the whole point — `Capabilities[v1.11]` has no `set_displayname?` because v1.12 added it.
- A layer that withdraws an operation does `extend Removals` and `removed :old, use: :new`, or `moved :old, to: "Other"`.

Entry points: `Async::Matrix::ClientServer::Client["v1.19"]`, `Async::Matrix::Events["v1.19"]`. Both go through `Versions[]`, which caches.

A class joins versioning by including `Versioned`. There is no registry.

Inside a method, reach sibling classes through `api::Whatever`, never the unversioned constant — that is what keeps a version's classes talking to each other.

## Layout

```
lib/async/matrix/api/<api>/          base classes, one file per concept
lib/async/matrix/abstract/api/<api>/ version layers, mirroring them
lib/async/matrix/events/             base event classes
lib/async/matrix/abstract/events/    their version layers
test/async/matrix/api/<api>/         tests, mirroring lib file for file
test/async/matrix/abstract/api/<api>/  test cases, layered by version the same way
test/operations/<api>.rb             the structural test: a method per operation the schema names
cops/                                the project's own rubocop cops
data/matrix-spec-v1.N/               the spec, one submodule per version
```

The five APIs are `client_server`, `server_server`, `identity`, `push_gateway`, `application_service`. The spec spells them with hyphens; Ruby with underscores. `bin/test --api` takes the hyphenated name.

`lib` and `test` mirror each other file for file — the `EachFileHasMatchingTest` cop enforces it. A new lib file needs its test file.

## Adding or changing something

1. Read the concept's `*-v1.N.deltas.yaml` to find which version changed what.
2. Put the code in that version's layer, or in the base class if every version has it.
3. Mirror it in `test/async/matrix/abstract/...` as a layered case module, and wire the concrete test in `test/async/matrix/api/...`.
4. `bin/test` (latest version only), then `bin/rubocop`.

Every layer container must declare every version highest first, and an empty one needs its `# No changes in v1.N.` comment. Two cops enforce this.

## Style the cops enforce

No `return`. No modifier `if`/`unless`. No assigning an `if`/`case`. No `begin ... end` assigned to a variable. Use `tap` where a method assigns and returns a local. Endless `def` for single-expression event methods. Never `respond_to?` an operation — the version already answers that.

Comments: one line per paragraph, never wrapped, and short. See `cops/comment_structure.rb` for the measurements.

## Scripts

Every `bin/` script carries a man page at the top. Read it before using it.

`bin/test` brings up a homeserver per version from `synapse/docker-compose.yml`. `--keep-alive` reuses it between runs, which is what you want while iterating. `--core` runs what belongs to no API.
