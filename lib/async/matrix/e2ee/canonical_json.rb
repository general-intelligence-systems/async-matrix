# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

module Async
  module Matrix
    module E2EE
      # The form an object is signed and hashed in.
      module CanonicalJSON
        # The keys which are never signed, because they are added after signing.
        UNSIGNED = [:signatures, :unsigned, "signatures", "unsigned"].freeze

        # The integers the specification allows, which are those an IEEE double represents exactly.
        INTEGERS = (-(2**53) + 1)..((2**53) - 1)

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
          # @returns [Object] the same value, as something the grammar allows.
          # @raises [ArgumentError] if the grammar has no way to write it.
          def canonical(object)
            case object
            when Hash
              self.members(object)
            when Array
              object.map{|value| self.canonical(value)}
            when Integer
              self.integer(object)
            when Float
              self.integer(self.whole(object))
            when Symbol
              object.to_s
            when String, true, false, nil
              object
            else
              raise ArgumentError, "Canonical JSON cannot represent #{object.class}!"
            end
          end

          # The members of an object, sorted by name, which is what gives one object one encoding.
          #
          # @parameter object [Hash] the object whose members to sort.
          # @returns [Hash] the members, in order.
          # @raises [ArgumentError] if two keys are the same name.
          def members(object)
            object.sort_by{|key, _| self.name(key)}.each_with_object({}) do |(key, value), sorted|
              name = self.name(key)

              if sorted.key?(name)
                raise ArgumentError, "Canonical JSON has one member named #{name.inspect}, not two!"
              end

              sorted[name] = self.canonical(value)
            end
          end

          # @parameter key [Object] the key to name.
          # @returns [String] the name it is written as.
          # @raises [ArgumentError] if it is not a name.
          def name(key)
            case key
            when String
              key
            when Symbol
              key.to_s
            else
              raise ArgumentError, "A Canonical JSON name is a string, not #{key.class}!"
            end
          end

          # @parameter value [Integer] the number to write.
          # @returns [Integer] the same number.
          # @raises [ArgumentError] if it is outside the range the specification allows.
          def integer(value)
            unless INTEGERS.cover?(value)
              raise ArgumentError, "Canonical JSON cannot represent #{value}, which is outside #{INTEGERS}!"
            end

            value
          end

          # The integer a float carries, because JSON writes one with an exponent and a parser reads a float.
          #
          # @parameter value [Float] the number to read.
          # @returns [Integer] the integer it is.
          # @raises [ArgumentError] if it is not one.
          def whole(value)
            unless value.finite? and value.to_i == value
              raise ArgumentError, "Canonical JSON cannot represent the float #{value}!"
            end

            value.to_i
          end
        end
      end
    end
  end
end
