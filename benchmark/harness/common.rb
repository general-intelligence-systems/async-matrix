# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"
require "time"
require "fileutils"

# What every harness shares: where results go, how a run is named, and the few numbers which are read the same way whichever harness is driving.
#
# A benchmark requires `harness` and calls `run_benchmark`. Which file that resolves to is chosen by the load path, so one benchmark can be timed, driven by benchmark-ips, or run under a profiler without being edited.

# Where a run's results are written: a file per benchmark, so that two runs can be compared rather than one overwriting the other.
DATA = File.expand_path("../data", __dir__)

# The library under test, which is this working copy unless bin/benchmark is comparing it against another revision.
#
# A comparison measures the baseline's `lib` with this revision's benchmarks and harness, because a benchmark which changed between the two sides is measuring itself. That is also what lets a revision from before the benchmarks existed be a baseline at all.
LIBRARY = File.expand_path(ENV.fetch("BENCHMARK_LIBRARY"){File.expand_path("../../lib", __dir__)})

# The file this run writes, which bin/benchmark overrides when it is collecting a set of runs together.
RESULTS = File.expand_path(ENV.fetch("BENCHMARK_RESULTS"){File.join(DATA, "#{Time.now.strftime("%F-%H%M%S")}.json")})

# The name a benchmark is reported under.
def benchmark_name
  directory = File.basename(File.dirname($PROGRAM_NAME))

  "#{directory}/#{File.basename($PROGRAM_NAME, ".rb")}"
end

# The resident set size in bytes.
def resident_size
  rollup = "/proc/#{Process.pid}/smaps_rollup"

  if File.exist?(rollup)
    line = File.read(rollup).lines.find{|candidate| candidate.start_with?("Rss")}

    1024 * Integer(line[/(\d+)/, 1])
  else
    # Where there is no procfs, ps knows, to the kilobyte:
    1024 * Integer(IO.popen(["ps", "-o", "rss=", "-p", Process.pid.to_s], &:read))
  end
end

# A path below the working directory, rather than one naming this machine.
def relative(path)
  # Both the directory and what it resolves to, because a working copy may be reached through a symlink and the path Ruby reports is not always the one the shell was given:
  roots = [Dir.pwd, File.realpath(Dir.pwd)].uniq

  roots.reduce(path.to_s){|value, root| value.delete_prefix("#{root}/")}
end

# The mean of the given samples.
def mean(samples)
  samples.sum / samples.size.to_f
end

# How much the samples varied about their mean.
def standard_deviation(samples)
  if samples.size < 2
    0.0
  else
    average = mean(samples)

    Math.sqrt(samples.sum{|sample| (sample - average)**2} / (samples.size - 1))
  end
end

# The middle sample, which is what a timing with a tail should be read by.
def median(samples)
  sorted = samples.sort
  middle = sorted.size / 2

  if sorted.size.odd?
    sorted[middle]
  else
    (sorted[middle - 1] + sorted[middle]) / 2.0
  end
end

# How far a typical sample sits from the median, which a single slow iteration cannot inflate the way it inflates a standard deviation.
def median_absolute_deviation(samples)
  centre = median(samples)

  median(samples.map{|sample| (sample - centre).abs})
end

# That deviation as a percentage of the median, which is what says whether two runs differ.
def relative_absolute_deviation(samples)
  centre = median(samples)

  if centre.zero?
    0.0
  else
    median_absolute_deviation(samples) / centre * 100
  end
end

# That deviation as a percentage of the mean, which is what says whether two runs differ.
def relative_deviation(samples)
  average = mean(samples)

  if average.zero?
    0.0
  else
    standard_deviation(samples) / average * 100
  end
end

# Write the results, with what every run records added to them.
def write_results(**results)
  # The footprint is read after a full collection, so that it is what the run is holding rather than what it has not got round to freeing:
  GC.start(full_mark: true, immediate_sweep: true)

  document = {
    "name" => benchmark_name,
    "harness" => HARNESS,
    "ruby" => RUBY_DESCRIPTION,
    "matrix_version" => ENV["MATRIX_VERSION"],
    "resident_size" => resident_size,
    "recorded_at" => Time.now.utc.iso8601,
    **results.transform_keys(&:to_s),
  }

  FileUtils.mkdir_p(File.dirname(RESULTS))
  File.write(RESULTS, JSON.pretty_generate(document))

  puts "Wrote #{RESULTS}."
end
