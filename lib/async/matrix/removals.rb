# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "error"

module Async
  module Matrix
    # Raised when an operation the version withdrew is called on it.
    class RemovedOperationError < Error
      # @parameter name [Symbol] the method which was called.
      # @parameter version [String] the version which withdrew it.
      # @parameter replacement [Symbol | nil] the method which took its place.
      def initialize(name, version, replacement = nil)
        if replacement
          super("##{name} was removed in #{version}: call ##{replacement} instead!")
        else
          super("##{name} was removed in #{version}!")
        end

        @name = name
        @version = version
        @replacement = replacement
      end

      # @attribute [Symbol] the method which was called.
      attr :name

      # @attribute [String] the version which withdrew it.
      attr :version

      # @attribute [Symbol | nil] the method which took its place.
      attr :replacement
    end

    # Extended by a layer which withdraws an operation.
    #
    # @example
    #   # v1.2 renamed the single session operations.
    #   module V1_2
    #     extend Removals
    #
    # @example
    #     removed :get_room_keys_by_session_id, use: :get_room_key_by_session_id
    #   end
    module Removals
      # The operations this layer withdrew.
      #
      # @returns [Hash] the method which took the place of each, which is nil where nothing did.
      def removals
        @removals ||= {}
      end

      # The version this layer carries, which is the version it is named for.
      #
      # @returns [String] the version, e.g. `v1.2`.
      def version
        "v#{self.name.split("::").last.delete_prefix("V").tr("_", ".")}"
      end

      # Withdraw an operation an earlier layer defined.
      #
      # Layers accumulate, so a method stays reachable at every later version unless a later layer takes it back.
      #
      # @parameter name [Symbol] the method to withdraw.
      # @parameter use [Symbol | nil] the method which took its place.
      def removed(name, use: nil)
        self.removals[name] = use

        version = self.version

        define_method(name) do |*arguments, **options, &block|
          raise RemovedOperationError.new(name, version, use)
        end
      end
    end
  end
end
