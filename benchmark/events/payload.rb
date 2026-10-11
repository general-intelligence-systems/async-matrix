# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# What the event benchmarks measure against, built from the schemas rather than captured from a homeserver.
#
# The schemas say what every type of every version carries, which is what the suite holds the event classes to. Building the payload from them therefore gets a realistic event for every type the version describes, reproducibly, and follows the version under test rather than whatever a homeserver happened to send the day somebody captured it.
#
# A field is given a plausible value for its declared type, and a field which picks a variant is given the value which picks it, so that dispatch lands on the class the schema says it should. What is being measured is the shape of the work - how many types, how many variants, how deep the envelope - rather than the particular strings.
#
# Not a benchmark, and not listed in benchmarks.yml, so bin/benchmark will not run it.

require "yaml"

# The payload the event benchmarks measure against.
module Payload
  # The schemas the payload is built from, which belong to the library under test rather than to this working copy.
  #
  # A comparison therefore builds each side's payload from that side's own schemas, because the schemas are what its event classes were generated from: measuring a revision against types it has never heard of would measure the fallback and call it decoding. Where the two differ the event count differs with them, which is what the recorded `events` figure is for.
  SCHEMAS = File.join(LIBRARY, "async", "matrix", "abstract", "events", "schemas")

  # A plausible value for each type a schema declares.
  VALUES = {
    "string" => "benchmark",
    "integer" => 1,
    "number" => 1.0,
    "boolean" => true,
    "object" => {},
    "array" => [],
  }.freeze

  # What a room event carries besides its content.
  ENVELOPE = {
    event_id: "$benchmark:example.com",
    sender: "@benchmark:example.com",
    origin_server_ts: 1_760_000_000_000,
    unsigned: {age: 1},
  }.freeze

  class << self
    # Every event the version describes: one per family, and one per variant of one.
    def events(version)
      paths = self.manifests(version)

      # Loudly, rather than measuring an empty batch: a revision whose schemas are elsewhere is a comparison which cannot be made, not one which found no work to do.
      if paths.empty?
        raise "No event schemas for #{version} under #{SCHEMAS}."
      end

      paths.flat_map do |path|
        entries = YAML.safe_load_file(path)["events"] || {}

        entries.each_value.map{|entry| self.event(entry)}
      end
    end

    # A sync response shaped as the specification shapes one, with the state events in the state and the rest in the timeline.
    def sync(version, rooms: 4)
      timeline, state = self.events(version).partition{|event| !event.key?(:state_key)}

      {
        next_batch: "s1_benchmark",
        rooms: {
          join: (1..rooms).to_h do |index|
            [:"!room#{index}:example.com", self.room(timeline, state)]
          end,
        },
      }
    end

    private

    # The schema manifests for a version, which are one file per family and not the deltas beside them.
    def manifests(version)
      Dir.glob(File.join(SCHEMAS, "*-#{version}.yaml")).reject do |path|
        path.end_with?(".deltas.yaml")
      end.sort
    end

    # One event, framed as the schema frames it.
    def event(entry)
      content = self.content(entry)

      case entry["framing"]
      when "state_event"
        {type: entry["type"], content: content, state_key: "@benchmark:example.com", **ENVELOPE}
      when "room_event"
        {type: entry["type"], content: content, **ENVELOPE}
      else
        {type: entry["type"], content: content}
      end
    end

    # The content the schema declares, with the fields which pick a variant set to what picks it.
    def content(entry)
      (entry["content"] || {}).to_h do |name, field|
        [name.to_sym, VALUES[field["type"]]]
      end.tap do |fields|
        (entry["variant"] || {}).each do |name, value|
          fields[name.to_sym] = value
        end
      end
    end

    # One joined room, which is the shape a timeline and a state arrive in.
    def room(timeline, state)
      {
        timeline: {events: timeline, limited: false, prev_batch: "p1_benchmark"},
        state: {events: state},
        ephemeral: {events: []},
        account_data: {events: []},
      }
    end
  end
end
