# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "stackprof"

require_relative "../harness/common"

# The profiling harness, which says where the time in a benchmark went rather than how much of it there was.
#
# This is the harness to reach for once a timing has moved and the question is why. It samples the stack, so the answer is statistical: a frame which does not appear was not sampled rather than not called, and a short benchmark is worth running for more iterations than it would be timed for.
#
# The whole profile is written beside the results as a dump, which `stackprof` reads: `stackprof --text benchmark/data/<run>/<name>.dump`, or `--method` for one frame's callers.

# Which harness drove the run, recorded with its results.
HARNESS = "harness-stackprof"

# What to sample: wall for the time something took, cpu for the time it spent working, object for what it allocated.
MODE = ENV.fetch("STACKPROF_MODE", "wall").to_sym

# How often to sample, in microseconds for wall and cpu, and in allocations for object.
INTERVAL = Integer(ENV.fetch("STACKPROF_INTERVAL", 100))

# How many times the block runs inside the profiler, and how many before it, so that loading code for the first time is not what the profile is of.
PROFILED_ITERATIONS = Integer(ENV.fetch("PROFILED_ITERATIONS", 100))
WARMUP_ITERATIONS = Integer(ENV.fetch("WARMUP_ITERATIONS", 2))

# How many of the heaviest frames to print.
REPORTED_FRAMES = Integer(ENV.fetch("REPORTED_FRAMES", 15))

# Profile the block, and report where its time went.
#
# The iteration bound a benchmark asks for is ignored: PROFILED_ITERATIONS says how many to profile.
def run_benchmark(maximum: nil, &block)
  WARMUP_ITERATIONS.times{block.call}

  profile = StackProf.run(mode: MODE, interval: INTERVAL, raw: true) do
    PROFILED_ITERATIONS.times{block.call}
  end

  announce(profile)

  write_results(
    mode: profile[:mode],
    interval: profile[:interval],
    profiled_iterations: PROFILED_ITERATIONS,
    samples: profile[:samples],
    missed_samples: profile[:missed_samples],
    gc_samples: profile[:gc_samples],
    frames: frames(profile).to_h{|frame| [label(frame), frame[:samples]]},
    dump: write_dump(profile),
  )
end

# Say which frames the samples landed in, by the time spent in the frame itself.
def announce(profile)
  total = profile[:samples]

  puts format(
    "%s: %d samples over %d iterations, %d in collection, %d missed.",
    benchmark_name,
    total,
    PROFILED_ITERATIONS,
    profile[:gc_samples].to_i,
    profile[:missed_samples].to_i,
  )

  frames(profile).each do |frame|
    puts format("  %5.1f%%  %5d  %s", frame[:samples] * 100.0 / total, frame[:samples], label(frame))
  end
end

# The heaviest frames, by their own samples rather than by those of everything they called.
def frames(profile)
  profile[:frames].each_value.sort_by{|frame| -frame[:samples]}.first(REPORTED_FRAMES)
end

# A frame, with the file it is in where it has one.
def label(frame)
  file = relative(frame[:file])

  if file.empty?
    frame[:name]
  else
    "#{frame[:name]} (#{file}:#{frame[:line]})"
  end
end

# Write the profile beside the results, because the stackprof command reads a dump and nothing reads a summary.
def write_dump(profile)
  path = RESULTS.sub(/\.json\z/, ".dump")

  FileUtils.mkdir_p(File.dirname(path))
  File.binwrite(path, Marshal.dump(profile))

  puts "Wrote #{path}."

  relative(path)
end
