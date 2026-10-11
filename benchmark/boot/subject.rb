# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# The program boot/require.rb spawns, rather than a benchmark of its own: it is not listed in benchmarks.yml, so bin/benchmark will not run it.
#
# It measures its own load and prints what it found, because what requiring the library costs is not what starting a Ruby costs, and timing the child from outside cannot tell the two apart.

require "json"

# The resident set size in bytes.
def resident_size
  File.read("/proc/#{Process.pid}/smaps_rollup")[/^Rss:\s+(\d+)/, 1].to_i * 1024
end

# What this process is carrying, which is read before and after the library is loaded.
def footprint
  {
    files: $LOADED_FEATURES.size,
    objects: ObjectSpace.count_objects[:TOTAL],
    classes: ObjectSpace.each_object(Class).count,
    modules: ObjectSpace.each_object(Module).count,
    resident_size: resident_size,
  }
end

before = footprint

started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
require "async/matrix"
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started

# Measured after a collection, so that the footprint is what the library needs held rather than what it littered on the way:
GC.start(full_mark: true, immediate_sweep: true)
after = footprint

print JSON.dump(
  load: elapsed,
  files: after[:files] - before[:files],
  objects: after[:objects] - before[:objects],
  classes: after[:classes] - before[:classes],
  modules: after[:modules] - before[:modules],
  footprint: after[:resident_size] - before[:resident_size],
)
