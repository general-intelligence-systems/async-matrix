# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# The version layers for `session.rb`. Each module mirrors the class of the same name, and holds only
# what a given specification version changed: the unversioned implementation stays in the class.
#
# Every version is declared, highest first, even when it changed nothing, so that a missing module
# is a mistake rather than a deliberate no-op. The schemas beside this file say what each version
# requires, and `session.rb-<version>.deltas.yaml` says what it changed.

module Async
  module Matrix
    module Abstract
      module ClientServer
        # Layers for {ruby Async::Matrix::ClientServer::Login}.
        module Login
          # No changes in v1.19.
          module V1_19
          end

          # No changes in v1.18.
          module V1_18
          end

          # No changes in v1.17.
          module V1_17
          end

          # No changes in v1.16.
          module V1_16
          end

          # No changes in v1.15.
          module V1_15
          end

          # No changes in v1.14.
          module V1_14
          end

          # No changes in v1.13.
          module V1_13
          end

          # No changes in v1.12.
          module V1_12
          end

          # No changes in v1.11.
          module V1_11
          end

          # No changes in v1.10.
          module V1_10
          end

          # No changes in v1.9.
          module V1_9
          end

          # No changes in v1.8.
          module V1_8
          end

          # No changes in v1.7.
          module V1_7
          end

          # No changes in v1.6.
          module V1_6
          end

          # No changes in v1.5.
          module V1_5
          end

          # No changes in v1.4.
          module V1_4
          end

          # No changes in v1.3.
          module V1_3
          end

          # No changes in v1.2.
          module V1_2
          end

          # v1.1 deprecated `home_server` in the login response, in favour of the server name carried
          # by the fully qualified user ID.
          module V1_1
            # @returns [String] the name of the homeserver the user belongs to.
            def home_server
              self.user_id.split(":", 2).last
            end
          end
        end
      end
    end
  end
end
