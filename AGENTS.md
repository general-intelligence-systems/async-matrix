# AGENTS.md

DO NOT FUCKING DARE USE GIT STASH!!!!!!!

## Hard rules

Never sweep the versions: one run, one specification version. Default to the latest, which is what bare `bin/test` does. Naming a single version to chase a version-specific failure is fine; running every version in order is not, unless expressly permitted. This holds however the script's options change: read its man page for how, not whether.

Always run `bin/rubocop`.
DO NOT consider whether rubocop cops are intended... ABIDE by them as holey scripture and word of god.

The schemas are generated. Never edit a `.yaml` under a `schemas/` directory, and never run `bin/update-spec`, `bin/update-event-spec`, `bin/generate-spec-deltas` or `bin/generate-event-spec-deltas`. They are the input you read, not output you produce.

## Essential reading: async-rest

This library is a client built on [async-rest](https://github.com/socketry/async-rest), and it does not reinvent any of it. Study that gem and its readme before writing code here — most confusion about this repo is really unfamiliarity with async-rest.

Its readme carries the reference links:

- Documentation — https://socketry.github.io/async-rest/
- Getting started guide — https://socketry.github.io/async-rest/guides/getting-started/index
- Releases — https://socketry.github.io/async-rest/releases/index

Two concepts, taken from Fielding, carry everything:

- A **resource** is a conceptual mapping to one or more entities. `Client`, `Room` and every navigator here is one.
- A **representation** is an instance of a resource at a given point in time. Every response here is one.

The gem is ten files. Read them rather than guessing, since the classes here subclass them: `resource.rb`, `representation.rb` and `wrapper.rb` answer most questions about what a call actually does. It is installed locally — `bundle info async-rest --path` says where.

The readme's "See also" names the sibling clients built this same way: async-ollama, async-discord, async-slack, cloudflare. They are the worked examples of this design, and are worth reading as such. Two of them are also the measuring stick for house style: `cops/comment_structure.rb` sets its limits from how async-rest, async-discord and async-ollama document themselves.

Then read this project's own `readme.md`, whose "Design" section says where Matrix forced a departure — absolute per-endpoint paths, errors raised by the wrapper, rate limits retried, a room as a resource with no representation, lazy representations.

## The model

Everything is driven by the Matrix specification, version by version. `MATRIX_API_VERSIONS.txt` lists them: v1.1 to v1.19.

Each concept has four files:

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
- A layer never takes anything away by itself. To withdraw something, see below.

Entry points: `Async::Matrix::ClientServer::Client["v1.19"]`, `Async::Matrix::Events["v1.19"]`. Both go through `Versions[]`, which caches.

A class joins versioning by including `Versioned`. There is no registry.

Inside a method, reach sibling classes through `api::Whatever`, never the unversioned constant — that is what keeps a version's classes talking to each other.

## Removals, renames and moves

Layers accumulate, so a method defined at v1.1 stays reachable at v1.19 unless a later layer takes it back. `lib/async/matrix/removals.rb` is how a layer takes it back: `extend Removals` in the layer of the version which withdrew the operation, then declare it.

Two declarations, and the difference between them is a claim about the schema:

| Declaration | What it says | The schema at that version |
| --- | --- | --- |
| `removed :old, use: :new` | the operation is gone | has no operation named `old` |
| `moved :old, to: "Other"` | another class answers it now | still has `old`, over in `Other` |

The structural test checks both claims against the schema, so the wrong one fails: a removal whose operation still exists, or a move whose operation does not.

Neither undefines the method. Both redefine it to raise `RemovedOperationError`, which carries `version`, `replacement` and `to` — the caller is told where the operation went instead of getting a bare `NoMethodError`. This is why `respond_to?` on an operation is banned: a withdrawn method still responds.

A rename is a removal plus the new method, in the same layer:

``` ruby
# v1.16 replaced the named fields with one field by key.
module V1_16
  extend Removals

  removed :get_display_name, use: :get_profile_field

  def get_profile_field(user_id, key)
    ...
  end
end
```

A move defines nothing: the class it went to has the method already. `registration.rb` hands `change_password` to `PasswordManagement` at v1.15.

Test a withdrawal in the matching layer of the test, by rescuing the error and asserting its fields — `version`, `replacement`, `to`. See `test/async/matrix/abstract/api/client_server/registration.rb`.

Where the spec versions an endpoint rather than renaming an operation — `send_join_v1` against `send_join_v2` — the server-server API has a class per endpoint version, and the older class withdraws its own operation.

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

The five APIs are `client_server`, `server_server`, `identity`, `push_gateway`, `application_service`. The spec spells them with hyphens; Ruby with underscores. Scripts take whichever the man page says.

`lib` and `test` mirror each other file for file — the `EachFileHasMatchingTest` cop enforces it. A new lib file needs its test file.

## Adding or changing something

1. Read the concept's `*-v1.N.deltas.yaml` to find which version changed what.
2. Put the code in that version's layer, or in the base class if every version has it.
3. Mirror it in `test/async/matrix/abstract/...` as a layered case module, and wire the concrete test in `test/async/matrix/api/...`.
4. `bin/test` on the latest version only, then `bin/rubocop`.

Every layer container must declare every version highest first, and an empty one needs its `# No changes in v1.N.` comment. Two cops enforce this.

## Running tests

The whole suite at the latest version, which is the default:

``` bash
bin/test
```

One API at one version, with the library narrating itself — this is the workhorse:

``` bash
CONSOLE_LEVEL=debug bin/test v1.1 --api client-server
```

`CONSOLE_LEVEL=debug` surfaces the `Console.debug` calls, which is how the E2EE machine, the device lists and the session sharing say what they are doing. Without it they are silent.

A run costs a container start, so keep the homeserver up while iterating and drive `sus` directly against it:

``` bash
bin/test --keep-alive v1.1 --api client-server
MATRIX_VERSION=v1.1 bundle exec sus test/async/matrix/api/client_server/capabilities.rb
```

Set `MATRIX_VERSION` to the version the homeserver that is still running was brought up as. A bare `sus` run defaults to the latest, which will not match a v1.1 homeserver and fails in ways that look like real bugs.

Every other knob is an environment variable with a default — `MATRIX_HOMESERVER`, `MATRIX_BACKEND`, `MATRIX_ACCOUNTS` and the rest. See `fixtures/async/matrix/client_context.rb` for what is read, and the `bin/test` man page for what the script sets.

### Always read the docker logs

A failing test is as often the homeserver refusing as it is the library. Read its logs before you change any code — the suite sees an `errcode`, the homeserver's log says why.

The rig is one compose project, `async-matrix`, with a service named for each specification version:

``` bash
docker compose --file synapse/docker-compose.yml logs v1.1
docker compose --file synapse/docker-compose.yml logs --follow v1.1
```

The other servers are services of their own, so log whichever answers the API under test: `sydent` for identity, `sygnal` for the push gateway, `appservice` for the stub that stands in for a bridge, and `oauth-synapse`, `oauth-mas`, `oauth-mas-user` for the OAuth rig.

**`bin/test` tears the rig down on the way out, which removes the containers and their logs with them.** So a failed run leaves nothing to read. Re-run with `--keep-alive` when you intend to look:

``` bash
CONSOLE_LEVEL=debug bin/test --keep-alive v1.1 --api client-server
docker compose --file synapse/docker-compose.yml logs v1.1
```

This applies to a homeserver that never comes up too: the start fails before a single test runs, and the teardown takes the evidence with it. `--keep-alive` is the only way to see why.

Each version mounts its own `synapse/homeserver.<version>.yaml`, because an older Synapse rejects settings a newer one accepts. A server which refuses to start, or answers 500, is usually that configuration rather than a bug here.

## Style the cops enforce

No `return`. No modifier `if`/`unless`. No assigning an `if`/`case`. No `begin ... end` assigned to a variable. Use `tap` where a method assigns and returns a local. Endless `def` for single-expression event methods. Never `respond_to?` an operation — the version already answers that.

Comments: one line per paragraph, never wrapped, and short. See `cops/comment_structure.rb` for the measurements.

## Scripts

Every `bin/` script carries a man page at the top, kept current with the script. Read it before using it, rather than guessing options or trusting what is written here.

`bin/test` brings a homeserver up in Docker to test against, so a run costs a container start. Its man page explains how to narrow a run and how to keep the homeserver alive between runs, which is what you want while iterating.

## The native extension

`ext/async_matrix_e2ee` is a Rust crate (magnus over [vodozemac](https://github.com/matrix-org/vodozemac)) which `rake compile` builds into `lib/async/matrix/async_matrix_e2ee.so`. `Cargo.toml` at the repository root is the workspace, because rb_sys runs `cargo metadata` from there.

**Nothing under `lib/` loads it.** `E2EE::Crypto` is the interface encryption is written against, and `E2EE::Plaintext` is the only implementation the library ships. The crate is the binding a real implementation will be built on, and the toolchain is kept wired up so that the release already ships precompiled gems on the day one is.

The `.so` is deliberately not in `spec.files`: see the `reject` in the gemspec. The *source* gem compiles its own at install time, and rake-compiler puts the right object into each precompiled platform gem itself.

## Release

```bash
gem kit bump [major|minor|patch]  # version.rb via the .erb, then relock
gem kit changelog --write         # draft this version's entry
bin/release-gem                   # build + push, source gem AND platform gems
```

`gem kit bump` renders `lib/async/matrix/version.rb` from `version.rb.erb`, blocks a bump onto a due deprecation deadline, and relocks with `BUNDLE_FROZEN=false` (bare `bundle install` inherits the devshell's frozen store Gemfile and fails).

`bin/release-gem` is **not** superseded by `gem kit release`, which does one `gem build` + one `gem push` and has no notion of per-platform gems. This gem has a native extension, so publishing only the source gem would put a Rust toolchain back in every user's install path. `bin/release-gem` builds the source gem locally and downloads the precompiled platform gems from the latest green `cross-compile.yml` run, so **push to async-rest and let that workflow finish before releasing**.

The tradeoff: `bin/release-gem` skips the `gem kit release` gates (changelog entry, deprecation deadlines, clean working tree). Run `gem kit release --dry-run` first to get them.

A relock cannot go through the devshell's `bundle` wrapper, which pins `BUNDLE_GEMFILE` to the read-only store copy. `gem kit bump` handles it; by hand, run bundler with the store's bundler lib and `BUNDLE_GEMFILE` pointed at the checkout.
