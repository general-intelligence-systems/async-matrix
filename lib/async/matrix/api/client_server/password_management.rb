# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../versioned"

module Async
  module Matrix
    module ClientServer
      # Changes a password, and recovers a forgotten one.
      #
      # The operations are not written yet: this is the class `password_management-v1.19.yaml` names.
      class PasswordManagement
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [PasswordManagement] the passwords.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
