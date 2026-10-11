# Benchmarks

What the library costs, measured against itself.

async-matrix is a client for a remote server, so a wall-clock figure taken end to end is mostly a figure about the homeserver. These benchmarks therefore measure the part which is ours: what it costs to load the library, to build the classes for a specification version, and to do the work which happens per message rather than per request. The benchmarks which need a homeserver are a separate tier, run against the rig `bin/test` brings up, and are not here yet.

Run them with `bin/benchmark`, which has a man page in its own header:

```bash
bin/benchmark                                      # everything
bin/benchmark --list                               # what there is, and what each measures
bin/benchmark --category headline                  # the numbers worth quoting
bin/benchmark versions                             # one directory of them
bin/benchmark --harness harness-bips versions/cached
bin/benchmark --compare main --category headline     # did the branch make anything worse?
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

## A note on the numbers

Read the median and the deviation beside it, not the mean. These timings have a tail: building a version lands between 2.0ms and 2.8ms most times through and takes 14ms when a collection falls inside the iteration, which moves the mean a long way and the median hardly at all. The default harness therefore leads with the median and the median absolute deviation, and prints the mean next to it so the tail is not hidden either. Both are recorded, with the raw timings, so a distribution can be looked at rather than inferred.

Benchmarks taken on a workstation also move with whatever else it is doing: the same `boot/require` reads 477ms on a quiet machine and 816ms against a Nix build, which is not a regression in anything. Run them against nothing else, and treat a change smaller than the deviation as unmeasured.

The two allocation figures are not the same figure, and should not be compared. The default harness reports `GC.stat(:total_allocated_objects)`, which counts every object the VM made including its own internal ones; `harness-memory` reports what memory_profiler can attribute to a line of Ruby, which is fewer. Each is consistent with itself across runs, which is what a regression is read from.

The benchmarks which need a homeserver - throughput, and the concurrency the library exists for - are a tier of their own against the rig `bin/test` brings up, and are not written yet.
