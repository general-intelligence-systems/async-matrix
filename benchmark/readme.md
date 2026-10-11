# Benchmarks

What the library costs, measured against itself.

async-matrix is a client for a remote server, so a wall-clock figure taken end to end is mostly a figure about the homeserver. These benchmarks therefore measure the part which is ours: what it costs to load the library, to build the classes for a specification version, and to do the work which happens per message rather than per request. The ones which do talk to a homeserver say so, and say what they are really measuring.

Run them with `bin/benchmark`, which has a man page in its own header:

```bash
bin/benchmark                                      # everything
bin/benchmark --list                               # what there is, and what each measures
bin/benchmark --category headline                  # the numbers worth quoting
bin/benchmark versions                             # one directory of them
bin/benchmark --harness harness-bips versions/cached
bin/benchmark --compare main --category headline     # did the branch make anything worse?
bin/benchmark --keep-alive homeserver                # against a real homeserver
```

## How a benchmark is put together

A benchmark says *what* to measure. A harness says *how*. The harness is chosen by the load path rather than named in the benchmark, so one benchmark file can be timed, driven by benchmark-ips, or later run under a profiler without being edited:

```ruby
require "harness"

run_benchmark do
  Async::Matrix::Versions[VERSION, NAMESPACE]
end
```

`bin/benchmark` puts the chosen harness directory on the load path, so `require "harness"` resolves to `benchmark/harness/harness.rb` or `benchmark/harness-bips/harness.rb` according to `--harness`. Both load `benchmark/harness/common.rb`, which is where results are written and where the few numbers read the same way whichever harness is driving - resident size, the mean, the deviation - live.

| Harness | What it reports | What it is for |
| --- | --- | --- |
| `harness` | Median and mean time per iteration, with the deviation and the objects allocated. | The default. The subjects it was written for happen once per process or once per request, where a rate is not what anybody asks. It stops at `MAXIMUM_ITERATIONS`, so a block faster than a millisecond is not asked for millions of them - that is a rate, and `harness-bips` measures rates properly. |
| `harness-bips` | Iterations per second, via benchmark-ips. | The subjects which happen many times per response, where a rate is the number that reads. |
| `harness-memory` | What one run allocated and kept, by location and by class, with the gem's full report written beside the results. | Once a timing moves and the suspicion is that something is allocating. One run is profiled rather than many: the same work allocates the same objects, so repeating it adds noise and nothing else. |
| `harness-stackprof` | Where the samples landed, and a profile dump the `stackprof` command reads. | Once a timing has moved and the question is why. |

A benchmark which measured something the harness cannot see for itself returns a `Hash`, and it is recorded alongside the timings. That is how `boot/require` reports the child's own measurement of the require, and how `versions/sweep` reports a figure per version. A benchmark measuring something tiny should return nothing, though: building a hash to report costs more than a microsecond of work does, so `events/dispatch` and `versions/cached` return nothing at all.

Reading a profile:

```bash
bin/benchmark --harness harness-stackprof events/sync
stackprof --text benchmark/data/<run>/events-sync.dump
stackprof --method 'Registry#content_class' benchmark/data/<run>/events-sync.dump
```

## Registering one

A benchmark is run because it is listed in `benchmarks.yml`, not because it is a file in a directory. That is what lets `boot/require` keep the program it spawns, `boot/subject.rb`, beside it without the driver mistaking it for a benchmark. Each entry carries a `desc` and a `category`:

- **headline** — the numbers worth quoting, and what a regression should be measured against.
- **micro** — a single call, measured as a rate.
- **other** — a benchmark which answers a question rather than guarding a number.

## Comparing two revisions

`bin/benchmark --compare <revision>` runs each benchmark twice - once against that revision's library, once against this working copy's - and reports what moved. The benchmarks and the harness come from this working copy both times, and only `lib/` differs: a benchmark which changed between the two revisions would otherwise be measuring itself. That is also what lets a revision from before these benchmarks existed serve as a baseline.

The revision is checked out into a temporary `git worktree` which is removed afterwards. The working copy is never touched, so a comparison can be run with uncommitted changes in it, which is the usual reason to want one.

The two sides of a benchmark are run back to back rather than every baseline and then every current. This matters more than it sounds: run apart, `events/wrap` reported +7.8% between two revisions whose decoding code is identical, because the machine drifted over the minutes in between. Interleaved, the same comparison reported +0.1%.

A change is only called a change when it is bigger than the runs it came from. Each result records how much that run varied, and a difference has to beat the two deviations added together, or `--threshold` (default 10%), whichever is larger. The verdict says what it had to beat:

```
benchmark                  baseline      current    change  verdict
events/dispatch              5.15us       5.33us     +3.6%  same (needed 10.0%)
events/wrap                128.55us     128.70us     +0.1%  same (needed 10.0%)
versions/build              3.065ms      3.008ms     -1.9%  same (needed 32.1%)

allocations                baseline      current    change  verdict
events/wrap                     539          539     +0.0%  same
```

**Allocations are the signal worth trusting.** The same code allocates the same objects however busy the machine is, so they get a floor of 1% where timings get 10%, and they are what CI gates on. A wall-clock figure from a shared runner is not reproducible to the few percent a regression shows up as, and gating on one only teaches everybody to ignore the job. `--gate all` (the default, for your own quiet machine), `--gate allocations` (what `.github/workflows/benchmark.yaml` uses), `--gate none` to report and exit 0.

## Results

Each run writes a directory under `benchmark/data`, holding one JSON document per benchmark. The directory is not checked in; the benchmarks are, which is the point - a benchmark is worth keeping so that the same thing is measured the same way next time.

The per-version and per-API figures are recorded rather than printed:

```bash
jq .per_version benchmark/data/*/versions-sweep.json
jq .per_namespace benchmark/data/*/versions-namespaces.json
```

## What is here

`boot/` is what a program pays to depend on the gem at all: `require "async/matrix"` loads over three hundred files. Measured in a fresh child per iteration, because `require` happens once per process, with the child measuring the require itself so that starting a Ruby is not counted as library cost.

`events/` is the per-message path, and the one walked most often in the library. A payload is built from the event schemas under `lib/async/matrix/abstract/events/schemas` rather than captured from a homeserver: the schemas are what the suite holds the event classes to, so a payload built from them covers every type the version describes, reproducibly, and follows `--version` like everything else. `sync` parses a sync-shaped document and wraps every event in it, which is the end to end figure; `wrap` is the same without the parse, which isolates what is ours; `dispatch` is the single hardest decision the registry makes; `registry` is what building it costs.

`versions/` is what the versioning costs. A version is built by deriving a class per versioned class and including a layer per version up to it, so building `v1.19` of the client-server API includes nineteen layers across a hundred and forty-five classes. `build` is what the first client of a version pays, `cached` is what every client after it pays, and `sweep` and `namespaces` say how that cost is distributed across the versions and the APIs.

## Requests, and why the stub exists

`requests/concurrency` is the benchmark for the reason this library is async: that one reactor can be waiting for many responses at once. It makes the same number of requests at each of several concurrencies and reports what that bought:

```
 concurrency       time        req/s   speedup
           1     399.6ms          160     1.00x
           2     213.1ms          300     1.87x
           8      66.5ms          963     6.01x
          32      30.5ms         2101    13.12x
          64      23.9ms         2683    16.75x
```

It runs against an in-process stub, not against a homeserver, and that is not a convenience. The first attempt pointed it at the rig and measured **1.03x** — because Synapse answers one request at a time, so sixty-four requests in flight come back no faster than sixty-four in a row. That figure describes Synapse's concurrency, not ours, and it would have read 1.03x however good the client was. The stub answers after a fixed delay and does no work, which leaves the client's own overlapping as the only thing the curve can be about. The delay is the point: concurrency does not make a response arrive sooner, it makes the waiting overlap, so a server which answered instantly would show a flat curve no matter what.

The stub binds an ephemeral port. An earlier version used a fixed one that turned out to be published by the rig's compose file, so Synapse quietly answered the requests and the numbers looked fine. Hence `Stub.answered_by_stub?`, which every benchmark here checks before believing anything.

## Against a real homeserver

`homeserver/` is the end to end tier, run against the rig `bin/test` brings up — same compose files, same `--backend`, same `--keep-alive`, same version list. It is opt-in: `bin/benchmark` leaves it out unless a name or `--homeserver` asks for it, and says which ones it left out, because starting a container is not what somebody who typed `bin/benchmark` was asking for.

| | median |
| --- | --- |
| `homeserver/versions` — cheapest unauthenticated request | 1.36ms |
| `homeserver/whoami` — the same with a token to look up | 1.51ms |
| `homeserver/sync` — one sync round trip, `timeout: 0` | 2.69ms |

These measure the whole system: this library, the socket, and a real homeserver doing real work. A figure here moves when Synapse changes, when the image changes, and when the machine is busy, so it should not be read as a regression in this library without checking the rest first. What it is good for is the thing the isolated benchmarks cannot tell you — that it all works at a speed anybody would want. The difference between `versions` and `whoami` is about what being logged in costs; `sync` against `events/sync` is the homeserver and the socket against the decoding.

## Crypto

`crypto/` is the federation signing path: pure CPU, no socket, no homeserver. These are the steadiest numbers here — deviations of one to six percent — because nothing in them waits for anything.

| | median | allocations |
| --- | --- | --- |
| `crypto/canonical_json` — render the form that gets signed | 16us | 46 |
| `crypto/signing` — canonical JSON, then Ed25519 | 58us | 50 |
| `crypto/verifying` — check a signature | 131us | 47 |
| `crypto/authorization` — sign a whole federation request | 81us | 117 |

Two things worth knowing fall straight out of these. **Verifying costs 2.3x what signing does** — Ed25519 is not symmetric, and verification is the side paid per *inbound* event, which a homeserver has more of than outbound. And canonical JSON is 16us of the 58us signing figure, so better than a quarter of signing is sorting keys in Ruby rather than doing cryptography; if signing ever looks slow, that is where to look before suspecting OpenSSL.

All four work on one shared event (`crypto/subject.rb`) of about the size a real one is, with a fixed seed rather than a random one — signing is the same work whatever the bytes are, and an input that changed between runs could not be compared across them, which is the point of `--compare`.

The Rust extension under `ext/async_matrix_e2ee` is **not** benchmarked. It needs `rb_sys` and `rake-compiler` to build, neither of which is in the Gemfile, and the gemspec declares no `extensions`, so there is nothing built to measure. Olm and Megolm throughput, and a comparison against a reference implementation, are worth having once the extension is part of the build.

## A note on the numbers

Read the median and the deviation beside it, not the mean. These timings have a tail: building a version lands between 2.0ms and 2.8ms most times through and takes 14ms when a collection falls inside the iteration, which moves the mean a long way and the median hardly at all. The default harness therefore leads with the median and the median absolute deviation, and prints the mean next to it so the tail is not hidden either. Both are recorded, with the raw timings, so a distribution can be looked at rather than inferred.

Benchmarks taken on a workstation also move with whatever else it is doing: the same `boot/require` reads 477ms on a quiet machine and 816ms against a Nix build, which is not a regression in anything. Run them against nothing else, and treat a change smaller than the deviation as unmeasured.

The two allocation figures are not the same figure, and should not be compared. The default harness reports `GC.stat(:total_allocated_objects)`, which counts every object the VM made including its own internal ones; `harness-memory` reports what memory_profiler can attribute to a line of Ruby, which is fewer. Each is consistent with itself across runs, which is what a regression is read from.

What is left is the Olm and Megolm side of E2EE, which waits on the Rust extension becoming part of the build - see the note under Crypto.
