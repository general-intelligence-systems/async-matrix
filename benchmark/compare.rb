# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# Compares two runs of the benchmarks, which is what `bin/benchmark --compare` reports with.
#
# A benchmark on its own says what something costs. Two of them say whether it changed, which is the question actually worth a workflow: a figure nobody compares against anything is a figure nobody reads.
#
# A change is called a change only when it is larger than the runs it was measured from. Each result carries how much that run varied, and a difference smaller than the sum of the two deviations has not been measured - it has been observed once. A floor sits under that, because two quiet runs can both report a small deviation and still not agree to a percent.
#
# Allocations are judged far more tightly than timings. The same code allocates the same objects whatever else the machine is doing, so a one percent move in an allocation count is a real change where a one percent move in a timing is weather. That makes allocations the more useful regression signal of the two, which is why they are reported even though nobody asked what they were.
#
# Which of the two is allowed to fail a comparison is the gate. Everything fails it by default, which is what somebody watching a run on their own machine wants. A shared machine - a CI runner, where the neighbours are invisible and the clock is not the one measured last time - should gate on allocations and read the timings as a report, because a timing there is not reproducible enough to block on and saying otherwise just teaches everybody to ignore the job.
#
# Not a benchmark, and not listed in benchmarks.yml.

require "json"

# Compares two runs of the benchmarks.
module Compare
  # How far a timing must move to be called a change, as a percentage, when the runs varied by less than that.
  FLOOR = 5.0

  # The same for an allocation count, which barely varies between runs of the same code.
  ALLOCATION_FLOOR = 1.0

  # What a comparison is allowed to fail on.
  GATES = {
    "all" => [:timing, :allocations],
    "allocations" => [:allocations],
    "none" => [],
  }.freeze

  # How a verdict is said, and whether it fails the comparison.
  VERDICTS = {
    slower: {label: "slower", regression: true},
    faster: {label: "faster", regression: false},
    same: {label: "same", regression: false},
  }.freeze

  class << self
    # The results of a run, by the name of the benchmark which wrote them.
    def results(directory)
      Dir.glob(File.join(directory, "*.json")).to_h do |path|
        document = JSON.parse(File.read(path))

        [document["name"], document]
      end
    end

    # Compare two runs, print what changed, and say whether anything which counts got worse.
    def call(baseline, current, floor, gate)
      before = self.results(baseline)
      after = self.results(current)

      shared = after.keys.select{|name| before.key?(name)}.sort
      gated = GATES.fetch(gate)

      self.report_timings(before, after, shared, floor)
      self.report_allocations(before, after, shared)
      self.report_unmatched(before, after)
      self.report_gate(gate, gated)

      self.regressions(before, after, shared, floor, gated).empty?
    end

    private

    # The figure a benchmark is compared on, which is the median where the harness reports one.
    def measurement(document)
      document["median"] || document["mean"]
    end

    # How much a run varied, as a percentage of what it measured.
    def noise(document)
      document["relative_absolute_deviation"] || document["relative_deviation"] || 0.0
    end

    # How far a figure moved, as a percentage, positive being worse.
    def change(before, after)
      (after - before) / before.to_f * 100
    end

    # What a change of that size means, given what it would have to exceed.
    def verdict(change, allowed)
      if change.abs <= allowed
        :same
      elsif change.positive?
        :slower
      else
        :faster
      end
    end

    # What a timing had to exceed to count: the two runs' deviations, or the floor, whichever is larger.
    def allowed(before, after, floor)
      [floor, self.noise(before) + self.noise(after)].max
    end

    # The benchmarks which got worse in a way the gate counts, which is what the exit status is taken from.
    def regressions(before, after, shared, floor, gated)
      shared.select do |name|
        timing = self.verdict(
          self.change(self.measurement(before[name]), self.measurement(after[name])),
          self.allowed(before[name], after[name], floor),
        )

        allocations = self.allocation_verdict(before[name], after[name])

        (gated.include?(:timing) and VERDICTS.fetch(timing)[:regression]) or
          (gated.include?(:allocations) and VERDICTS.fetch(allocations)[:regression])
      end
    end

    # Say what was allowed to fail the comparison, so that a green run is not mistaken for more than it was.
    def report_gate(gate, gated)
      puts

      if gated.empty?
        puts "Gate #{gate}: nothing here can fail this comparison."
      else
        puts "Gate #{gate}: #{gated.join(" and ")} can fail this comparison."
      end
    end

    # What happened to a benchmark's allocations, or `same` where it does not report any.
    def allocation_verdict(before, after)
      if before["allocations"] and after["allocations"] and before["allocations"].positive?
        self.verdict(self.change(before["allocations"], after["allocations"]), ALLOCATION_FLOOR)
      else
        :same
      end
    end

    def report_timings(before, after, shared, floor)
      puts
      puts format("%-22s %12s %12s %9s  %s", "benchmark", "baseline", "current", "change", "verdict")

      shared.each do |name|
        was = self.measurement(before[name])
        now = self.measurement(after[name])
        moved = self.change(was, now)
        allowed = self.allowed(before[name], after[name], floor)

        puts format(
          "%-22s %12s %12s %+8.1f%%  %s",
          name,
          self.duration(was),
          self.duration(now),
          moved,
          self.explain(self.verdict(moved, allowed), allowed),
        )
      end
    end

    def report_allocations(before, after, shared)
      counted = shared.select{|name| before[name]["allocations"] and after[name]["allocations"]}

      unless counted.empty?
        puts
        puts format("%-22s %12s %12s %9s  %s", "allocations", "baseline", "current", "change", "verdict")

        counted.each do |name|
          was = before[name]["allocations"]
          now = after[name]["allocations"]

          puts format(
            "%-22s %12d %12d %+8.1f%%  %s",
            name,
            was.round,
            now.round,
            self.change(was, now),
            VERDICTS.fetch(self.allocation_verdict(before[name], after[name]))[:label],
          )
        end
      end
    end

    # The benchmarks which ran on one side only, which is what a new benchmark or a baseline too old to run it looks like.
    def report_unmatched(before, after)
      added = after.keys.reject{|name| before.key?(name)}.sort
      removed = before.keys.reject{|name| after.key?(name)}.sort

      unless added.empty?
        puts
        puts "No baseline, so not compared: #{added.join(", ")}."
      end

      unless removed.empty?
        puts
        puts "Did not run against this revision: #{removed.join(", ")}."
      end
    end

    # A verdict, with what the change had to beat to earn it.
    def explain(verdict, allowed)
      format("%s (needed %.1f%%)", VERDICTS.fetch(verdict)[:label], allowed)
    end

    # A time, in the unit which makes it readable.
    def duration(seconds)
      if seconds >= 0.001
        format("%.3fms", seconds * 1000)
      else
        format("%.2fus", seconds * 1_000_000)
      end
    end
  end
end

baseline, current, floor, gate = ARGV

unless Compare.call(baseline, current, Float(floor || Compare::FLOOR), gate || "all")
  # Flushed first, so that the reason reaches a log after the table it is about rather than before it:
  $stdout.flush

  warn "Something got worse. Rerun against a quiet machine before believing it."
  exit 1
end
