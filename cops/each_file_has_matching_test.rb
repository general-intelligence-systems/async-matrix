# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "rubocop"

module RuboCop
  module Cop
    module AsyncMatrix
      # Checks that `lib` and `test` mirror each other, file for file.
      #
      # `lib/async/matrix/api/client_server/rooms.rb` is tested by
      # `test/async/matrix/api/client_server/rooms.rb`, and nothing else. Keeping the two trees the
      # same shape means the question "is this tested?" is answered by the path rather than by
      # reading the suite, and renaming a file without renaming its test is a failure rather than a
      # test which quietly stops describing anything.
      #
      # The check runs in both directions: a file with no test, and a test with no file. Genuine
      # exceptions - an entry point which only requires other files, a test for something which
      # does not live in `lib` - belong in `Exclude`, where they are written down.
      #
      # @example
      #   # bad
      #   lib/async/matrix/api/client_server/rooms.rb   # and no test
      #
      #   # bad
      #   test/async/matrix/rooms.rb                    # and no such file in lib
      #
      #   # good
      #   lib/async/matrix/api/client_server/rooms.rb
      #   test/async/matrix/api/client_server/rooms.rb
      class EachFileHasMatchingTest < Base
        MSG_MISSING_TEST = "There is no test for this file: add `%<expected>s`."

        MSG_MISSING_FILE = "There is nothing for this test to describe: expected `%<expected>s`."

        def on_new_investigation
          path = processed_source.file_path

          return unless path
          return unless File.extname(path) == ".rb"

          library = cop_config.fetch("LibraryRoot", "lib")
          test = cop_config.fetch("TestRoot", "test")

          if relative = self.relative_to(path, library)
            self.require_counterpart(path, relative, test, MSG_MISSING_TEST)
          elsif relative = self.relative_to(path, test)
            self.require_counterpart(path, relative, library, MSG_MISSING_FILE)
          end
        end

        private

        # The path below the given root, and the root it was found under.
        #
        # The last occurrence wins, so a checkout inside a directory which is itself called `lib`
        # resolves against the project rather than against its parent.
        #
        # @returns [Array(String, String) | nil] the project root and the path below it.
        def relative_to(path, root)
          absolute = File.expand_path(path)
          segments = absolute.split(File::SEPARATOR)

          index = segments.rindex(root)

          return nil unless index

          [File.join(segments[0...index]), File.join(segments[(index + 1)..])]
        end

        def require_counterpart(path, found, root, message)
          project, relative = found

          expected = File.join(project, root, relative)

          return if File.exist?(expected)

          add_global_offense(format(message, expected: self.readable(expected, project)))
        end

        # The expected path, relative to the project, since an absolute path in a message is noise.
        def readable(expected, project)
          expected.delete_prefix("#{project}#{File::SEPARATOR}")
        end
      end
    end
  end
end
