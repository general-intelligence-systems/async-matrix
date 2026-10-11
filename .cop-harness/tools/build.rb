# frozen_string_literal: true

# Builds a fixture corpus which triggers each custom cop, so that a rewrite of the cops can be
# checked against the behaviour of the one it replaces. Run from the harness directory.

require "fileutils"

ROOT = File.expand_path("../corpus", __dir__)
PROJECT = File.expand_path("../..", __dir__)
VERSIONS = File.readlines(File.join(PROJECT, "MATRIX_API_VERSIONS.txt"), chomp: true).reject(&:empty?)
LAYERS = VERSIONS.map { |v| "V#{v.delete_prefix("v").tr(".", "_")}" }.reverse

def write(path, content)
  full = File.join(ROOT, path)
  FileUtils.mkdir_p(File.dirname(full))
  File.write(full, content)
end

FileUtils.rm_rf(Dir.glob(File.join(ROOT, "{lib,test}")))

# --- Local/BeginBlockAssignment -------------------------------------------------------------
write "lib/fixtures/begin_block_assignment.rb", <<~'RB'
  # frozen_string_literal: true

  x = begin
    1
  end

  @y = begin
    2
  end

  @@z = begin
    3
  end

  $g = begin
    4
  end

  ok = 1
RB

# --- Local/NoConditionalAssignment ----------------------------------------------------------
write "lib/fixtures/no_conditional_assignment.rb", <<~'RB'
  # frozen_string_literal: true

  a = if cond
    1
  else
    2
  end

  b = case value
  when 1 then :one
  else :other
  end

  c = cond ? :ok : :no

  @d = if cond
    1
  end

  obj.status = cond ? :ok : :pending

  e = 1
RB

# --- Local/NoModifierIf ---------------------------------------------------------------------
write "lib/fixtures/no_modifier_if.rb", <<~'RB'
  # frozen_string_literal: true

  def one(task)
    call if task
  end

  def two(task)
    call unless task
  end

  def three(task)
    if task
      call
    end
  end
RB

# --- Local/NoReturn -------------------------------------------------------------------------
write "lib/fixtures/no_return.rb", <<~'RB'
  # frozen_string_literal: true

  def guard(value)
    if value
      return 1
    end

    2
  end

  def bare(value)
    if value
      return
    end

    3
  end

  def unless_guard(value)
    unless value
      return 4
    end

    5
  end

  def modifier(value)
    return 6 if value
    7
  end

  def plain
    8
  end
RB

# --- Local/UseTap ---------------------------------------------------------------------------
write "lib/fixtures/use_tap.rb", <<~'RB'
  # frozen_string_literal: true

  def tappable(params)
    column = params[:id].to_s
    check(column)
    column
  end

  def reassigned(params)
    column = params[:id].to_s
    column = other(column)
    column
  end

  def not_returned(params)
    column = params[:id].to_s
    check(column)
    nil
  end

  def self.singleton(params)
    name = params[:name].to_s
    check(name)
    name
  end
RB

# --- Local/CommentStructure -----------------------------------------------------------------
write "lib/fixtures/comment_structure.rb", <<~'RB'
  # frozen_string_literal: true

  # Released under the MIT License.
  # Copyright, 2026, by Nathan K.

  # This summary paragraph is deliberately wrapped across
  # two lines, which the cop forbids.
  module Wrapped
  end

  # This module summary is far too long because it keeps going and going well past the ten words a module is allowed.
  module TooLong
  end

  # Short summary.
  module Fine
  end

  class Subject
    # Described in prose with no annotations at all, which the cop forbids in lib.
    def undocumented(value)
      value
    end

    # @parameter value [Integer] the value.
    # @returns [Integer] the value.
    def documented(value)
      value
    end

    # @parameter value [Integer] the summary of this annotation is wrapped
    #   across two lines, which the cop forbids.
    def wrapped_annotation(value)
      value
    end
  end
RB

# --- Local/SingleLineMethodsForEvents -------------------------------------------------------
write "lib/async/matrix/events/fixture.rb", <<~'RB'
  # frozen_string_literal: true

  module Async
    module Matrix
      module Events
        # An event.
        class Fixture
          # @returns [String] the type.
          def event_type
            "m.room.message"
          end

          # @parameter fields [Hash] the fields.
          # @returns [Fixture] the fixture.
          def build(**fields)
            new(fields)
          end

          # @returns [String] the type.
          def already = "m.room.other"

          # @returns [Integer] the sum.
          def multi
            a = 1
            a + 1
          end
        end
      end
    end
  end
RB

# --- AsyncMatrix/AbstractModuleVersionOrder + NoChangesComment ------------------------------
complete = LAYERS.map { |l| "          # No changes in v#{l.delete_prefix("V").tr("_", ".")}.\n          module #{l}\n          end" }.join("\n\n")
write "lib/async/matrix/abstract/api/good.rb", <<~RB
  # frozen_string_literal: true

  module Async
    module Matrix
      module Abstract
        module API
          module Concept
  #{complete.lines.map { |l| l.chomp.empty? ? "" : "  #{l}" }.join("\n")}
            end
          end
        end
      end
    end
  end
RB

missing = LAYERS.reject { |l| l == "V1_18" }
ascending = LAYERS.reverse
write "lib/async/matrix/abstract/api/missing.rb", <<~RB
  # frozen_string_literal: true

  module Async
    module Matrix
      module Abstract
        module API
          module Concept
  #{missing.map { |l| "            module #{l}\n            end" }.join("\n\n")}
            end
          end
        end
      end
    end
  end
RB

write "lib/async/matrix/abstract/api/ascending.rb", <<~RB
  # frozen_string_literal: true

  module Async
    module Matrix
      module Abstract
        module API
          module Concept
  #{ascending.map { |l| "            module #{l}\n            end" }.join("\n\n")}
            end
          end
        end
      end
    end
  end
RB

write "lib/async/matrix/abstract/api/unknown.rb", <<~RB
  # frozen_string_literal: true

  module Async
    module Matrix
      module Abstract
        module API
          module Concept
  #{LAYERS.map { |l| "            module #{l}\n            end" }.join("\n\n")}

              module V9_9
              end
            end
          end
        end
      end
    end
  end
RB

write "lib/async/matrix/abstract/api/comments.rb", <<~'RB'
  # frozen_string_literal: true

  module Async
    module Matrix
      module Abstract
        module API
          module Other
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.17.
            module V1_18
            end

            module V1_17
            end

            # v1.16 added the thing.
            module V1_16
              def thing
              end
            end
          end
        end
      end
    end
  end
RB

# --- AsyncMatrix/EachFileHasMatchingTest ----------------------------------------------------
write "lib/fixtures/untested.rb", "# frozen_string_literal: true\n"
write "test/fixtures/undescribed.rb", "# frozen_string_literal: true\n"
write "lib/fixtures/paired.rb", "# frozen_string_literal: true\n"
write "test/fixtures/paired.rb", "# frozen_string_literal: true\n"

puts "fixtures written under #{ROOT}"
