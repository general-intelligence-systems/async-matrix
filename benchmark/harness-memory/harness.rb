# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "memory_profiler"

require_relative "../harness/common"

# The memory harness, which says what one run of a benchmark allocated and what it kept, and where from.
#
# One run is profiled rather than many, because an allocation count does not need repeating the way a timing does: the same work allocates the same objects, and the only thing more runs would add is the noise of a collection landing in the middle of one.
#
# What is allocated and then dropped costs collection; what is retained costs for the life of the process. They are reported separately because a change which trades one for the other is not a regression, and a change which turns the first into the second is.

# Which harness drove the run, recorded with its results.
HARNESS = "harness-memory"

# How many times the block runs before it is profiled, so that what the report shows is the work rather than the code being loaded for the first time.
WARMUP_ITERATIONS = Integer(ENV.fetch("WARMUP_ITERATIONS", 2))

# How many of the heaviest locations to print.
REPORTED_LOCATIONS = Integer(ENV.fetch("REPORTED_LOCATIONS", 10))

# Profile the block, and report what it allocated.
#
# The iteration bound a benchmark asks for is ignored: this harness runs it once.
def run_benchmark(maximum: nil, &block)
  WARMUP_ITERATIONS.times{block.call}

  report = MemoryProfiler.report(&block)

  announce(report)

  write_results(
    allocated_objects: report.total_allocated,
    allocated_bytes: report.total_allocated_memsize,
    retained_objects: report.total_retained,
    retained_bytes: report.total_retained_memsize,
    allocated_by_location: locations(report.allocated_memory_by_location),
    retained_by_location: locations(report.retained_memory_by_location),
    allocated_by_class: locations(report.allocated_memory_by_class),
    full_report: write_report(report),
  )
end

# Say what the run came to, and where the weight of it was.
def announce(report)
  puts format(
    "%s: %d objects allocated in %s, %d retained in %s.",
    benchmark_name,
    report.total_allocated,
    scale(report.total_allocated_memsize),
    report.total_retained,
    scale(report.total_retained_memsize),
  )

  report.allocated_memory_by_location.first(REPORTED_LOCATIONS).each do |entry|
    puts format("  %10s  %s", scale(entry[:count]), relative(entry[:data]))
  end
end

# The locations as they are recorded, which is a hash rather than the array the gem reports.
def locations(entries)
  entries.first(REPORTED_LOCATIONS).to_h{|entry| [relative(entry[:data]), entry[:count]]}
end

# Bytes, as something a reader can hold in their head.
def scale(bytes)
  MemoryProfiler::Results.new.scale_bytes(bytes)
end

# Write the gem's own report beside the results, because the hundred lines it runs to are worth having and are not worth printing.
def write_report(report)
  path = RESULTS.sub(/\.json\z/, ".txt")

  FileUtils.mkdir_p(File.dirname(path))

  File.open(path, "w") do |file|
    report.pretty_print(to_file: file, scale_bytes: true, detailed_report: true)
  end

  puts "Wrote #{path}."

  relative(path)
end
