# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    # How an operation ID is named in Ruby.
    module Operations
      # The operation IDs which cannot be split by rule, because the identifier does not say where one word ends: `IdP` is one word, and `3PIDMSISDN` is two.
      IRREGULAR = {
        "redirectToIdP" => :redirect_to_idp,
        "requestTokenTo3PIDMSISDN" => :request_token_to_3pid_msisdn,
      }.freeze

      class << self
        # The method name an operation ID calls for.
        #
        # Shared by the tests and the cops.
        #
        # @parameter operation [String] the operation ID.
        # @returns [Symbol] the method name.
        def method_name(operation)
          IRREGULAR.fetch(operation){self.underscore(operation)}
        end

        # The snake_case form of a camelCase identifier.
        #
        # The specification names operations in camelCase and Ruby names methods in snake_case, so `getRoomEvents` is owed `get_room_events`.
        #
        # @parameter operation [String] the operation ID.
        # @returns [Symbol] the method name.
        def underscore(operation)
          # `getRoomEvents` -> `get_Room_Events`:
          spaced = operation.gsub(/([a-z])([A-Z])/, '\\1_\\2')

          # `add3PID` -> `add_3PID`:
          spaced = spaced.gsub(/([A-Za-z])(\d)/, '\\1_\\2')

          # A plural acronym is one word, so that `3PIDs` does not become `3pi_ds`:
          spaced = spaced.gsub(/([A-Z]{2,})s(?![a-z])/){"#{$1.downcase}s"}

          # `requestTokenTo3PIDEmail` -> `..._3PID_Email`:
          spaced = spaced.gsub(/([A-Z]+)([A-Z][a-z])/, '\\1_\\2')

          spaced.downcase.to_sym
        end
      end
    end
  end
end
