# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "error"

module Async
  module Matrix
    # The form a key takes when a person reads it.
    module KeyRepresentation
      # The two bytes which say that what follows is one of these.
      HEADER = "\x8B\x01".b

      # The alphabet bitcoin addresses use, which leaves out the characters which look alike.
      ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

      # How many characters go between one space and the next.
      GROUP = 4

      # The bytes a representation carries besides the key itself.
      OVERHEAD = HEADER.bytesize + 1

      class << self
        # @parameter bytes [String] the raw key.
        # @returns [String] the key as a person reads it, in groups of four characters.
        def encode(bytes)
          body = HEADER + bytes.b

          self.group(self.base58(body + self.parity(body).chr))
        end

        # @parameter string [String] the key as a person typed it, whose whitespace does not matter.
        # @parameter length [Integer | nil] the bytes the key must be, where the caller knows.
        # @returns [String] the raw key.
        # @raises [InvalidKeyError] if the alphabet, the length, the header or the parity is wrong.
        def decode(string, length: nil)
          decoded = self.bytes(string.gsub(/\s+/, ""))

          self.check_size(decoded, length)

          key = decoded.byteslice(HEADER.bytesize, decoded.bytesize - OVERHEAD)

          self.check(decoded.byteslice(0, HEADER.bytesize), key, decoded.getbyte(decoded.bytesize - 1))

          key
        end

        # The length is checked first, so that a key of the wrong size says so rather than failing the parity.
        #
        # @parameter decoded [String] the bytes the representation held.
        # @parameter length [Integer | nil] the bytes the key must be, where the caller knows.
        # @raises [InvalidKeyError] if there is no room for a key, or it is not the length wanted.
        def check_size(decoded, length)
          unless decoded.bytesize > OVERHEAD
            raise InvalidKeyError, "A key representation is a header, a key and a parity byte, which #{decoded.bytesize} bytes cannot be!"
          end

          unless length.nil? or decoded.bytesize == length + OVERHEAD
            raise InvalidKeyError, "This key is #{decoded.bytesize - OVERHEAD} bytes, and #{length} was expected!"
          end
        end

        # @parameter header [String] the bytes the representation began with.
        # @parameter key [String] the key it carried.
        # @parameter parity [Integer] the parity byte it ended with.
        # @raises [InvalidKeyError] if the header or the parity is wrong.
        def check(header, key, parity)
          unless header == HEADER
            raise InvalidKeyError, "A key representation begins with #{HEADER.unpack1("H*")}, not #{header.unpack1("H*")}!"
          end

          unless parity == self.parity(HEADER + key)
            raise InvalidKeyError, "The parity byte of this key representation does not match the key!"
          end
        end

        # Every byte of the array exclusive ored together, including the header.
        #
        # @parameter bytes [String] the bytes to fold.
        # @returns [Integer] the parity byte.
        def parity(bytes)
          bytes.each_byte.reduce(0, :^)
        end

        # @parameter string [String] the characters to space out.
        # @returns [String] them, in groups of four.
        def group(string)
          string.scan(/.{1,#{GROUP}}/).join(" ")
        end

        # @parameter bytes [String] the bytes to write.
        # @returns [String] them, in base58.
        def base58(bytes)
          number = bytes.each_byte.reduce(0){|total, byte| (total << 8) | byte}
          digits = []

          while number > 0
            number, remainder = number.divmod(ALPHABET.length)
            digits.unshift(ALPHABET[remainder])
          end

          (ALPHABET[0] * self.leading(bytes.each_byte, 0)) + digits.join
        end

        # @parameter string [String] the base58 to read.
        # @returns [String] the bytes it holds.
        # @raises [InvalidKeyError] if it holds a character the alphabet does not.
        def bytes(string)
          number = string.each_char.reduce(0) do |total, character|
            index = ALPHABET.index(character)

            unless index
              raise InvalidKeyError, "#{character.inspect} is not a base58 character!"
            end

            (total * ALPHABET.length) + index
          end

          ("\x00".b * self.leading(string.each_char, ALPHABET[0])) + self.octets(number)
        end

        # Zero is no bytes at all, because the leading zero bytes are counted on their own.
        #
        # @parameter number [Integer] the number to write.
        # @returns [String] its bytes, most significant first.
        def octets(number)
          digits = number.to_s(16).delete_prefix("0")

          [digits.length.even? ? digits : "0#{digits}"].pack("H*")
        end

        # @parameter values [Enumerator] the values to count through.
        # @parameter zero [Object] the value which counts as nothing.
        # @returns [Integer] how many of them begin the sequence.
        def leading(values, zero)
          values.take_while{|value| value == zero}.count
        end
      end
    end
  end
end
