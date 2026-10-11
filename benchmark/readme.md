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

A benchmark which measured something the harness cannot see for itself returns a `Hash`, and it is recorded alongside the timings. That is how `boot/require` reports the child's own measurement of the require, and how `versions/sweep` reports a figure per version.

## Registering one

A benchmark is run because it is listed in `benchmarks.yml`, not because it is a file in a directory. That is what lets `boot/require` keep the program it spawns, `boot/subject.rb`, beside it without the driver mistaking it for a benchmark. Each entry carries a `desc` and a `category`:

- **headline** — the numbers worth quoting, and what a regression should be measured against.
- **micro** — a single call, measured as a rate.
- **other** — a benchmark which answers a question rather than guarding a number.

## Results

Each run writes a directory under `benchmark/data`, holding one JSON document per benchmark. The directory is not checked in; the benchmarks are, which is the point - a benchmark is worth keeping so that the same thing is measured the same way next time.

The per-version and per-API figures are recorded rather than printed:

```bash
jq .per_version benchmark/data/*/versions-sweep.json
jq .per_namespace benchmark/data/*/versions-namespaces.json
```

## What is here

`boot/` is what a program pays to depend on the gem at all: `require "async/matrix"` loads over three hundred files. Measured in a fresh child per iteration, because `require` happens once per process, with the child measuring the require itself so that starting a Ruby is not counted as library cost.

`versions/` is what the versioning costs. A version is built by deriving a class per versioned class and including a layer per version up to it, so building `v1.19` of the client-server API includes nineteen layers across a hundred and forty-five classes. `build` is what the first client of a version pays, `cached` is what every client after it pays, and `sweep` and `namespaces` say how that cost is distributed across the versions and the APIs.

## A note on the numbers

Read the median and the deviation beside it, not the mean. These timings have a tail: building a version lands between 2.0ms and 2.8ms most times through and takes 14ms when a collection falls inside the iteration, which moves the mean a long way and the median hardly at all. The default harness therefore leads with the median and the median absolute deviation, and prints the mean next to it so the tail is not hidden either. Both are recorded, with the raw timings, so a distribution can be looked at rather than inferred.

Benchmarks taken on a workstation also move with whatever else it is doing: the same `boot/require` reads 477ms on a quiet machine and 816ms against a Nix build, which is not a regression in anything. Run them against nothing else, and treat a change smaller than the deviation as unmeasured.

Comparing two revisions properly - running both and reporting the ratio - is `--compare`, which is not written yet.
