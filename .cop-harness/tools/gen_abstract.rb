# frozen_string_literal: true

# Writes the version-layer fixtures, nesting the modules with explicit indentation so the files parse.

require "fileutils"

ROOT = File.expand_path("../corpus", __dir__)
PROJECT = File.expand_path("../..", __dir__)
VERSIONS = File.readlines(File.join(PROJECT, "MATRIX_API_VERSIONS.txt"), chomp: true).reject(&:empty?)
LAYERS = VERSIONS.map { |v| "V#{v.delete_prefix("v").tr(".", "_")}" }.reverse

OUTER = %w[Async Matrix Abstract API Concept].freeze

# The file, with the layers nested inside Async::Matrix::Abstract::API::Concept.
def build(layers, commented: false)
  lines = ["# frozen_string_literal: true", ""]

  OUTER.each_with_index do |name, depth|
    lines << "#{"  " * depth}module #{name}"
  end

  inner = "  " * OUTER.size

  layers.each_with_index do |layer, index|
    lines << "" unless index.zero?

    if commented
      version = layer.delete_prefix("V").tr("_", ".")
      lines << "#{inner}# No changes in v#{version}."
    end

    lines << "#{inner}module #{layer}"
    lines << "#{inner}end"
  end

  OUTER.size.times do |depth|
    lines << "#{"  " * (OUTER.size - 1 - depth)}end"
  end

  "#{lines.join("\n")}\n"
end

def write(name, content)
  path = File.join(ROOT, "lib/async/matrix/abstract/api", name)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, content)
end

write "good.rb", build(LAYERS, commented: true)
write "missing.rb", build(LAYERS.reject { |l| l == "V1_18" })
write "ascending.rb", build(LAYERS.reverse)
write "unknown.rb", build(LAYERS + ["V9_9"])

puts "wrote 4 abstract fixtures"
