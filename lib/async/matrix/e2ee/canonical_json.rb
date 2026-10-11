# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "json"

module Async
  module Matrix
    module E2EE
      # The form an object is signed and hashed in.
      module CanonicalJSON
        # The keys which are never signed, because they are added after signing.
        UNSIGNED = [:signatures, :unsigned, "signatures", "unsigned"].freeze

        class << self
          # Keys are sorted, there is no insignificant whitespace, and a float cannot be represented.
          #
          # @parameter object [Object] the object to render.
          # @returns [String] its canonical form.
          def dump(object)
            ::JSON.generate(self.canonical(object))
          end

          # The object as it is signed, without the fields which carry the signature itself.
          #
          # @parameter object [Hash] the object to sign.
          # @returns [String] its canonical form.
          def for_signing(object)
            self.dump(object.reject{|key, _| UNSIGNED.include?(key)})
          end

          # @parameter object [Object] the object to convert.
          # @returns [Object] the same object with its keys sorted and its names as strings.
          def canonical(object)
            case object
            when Hash
              object.sort_by{|key, _| key.to_s}.each_with_object({}) do |(key, value), sorted|
                sorted[key.to_s] = self.canonical(value)
              end
            when Array
              object.map{|value| self.canonical(value)}
            when Float
              raise ArgumentError, "Canonical JSON cannot represent the float #{object}!"
            when Symbol
              object.to_s
            else
              object
            end
          end
        end
      end
    end
  end
end
