# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../error"
require_relative "server_name"

module Async
  module Matrix
    module Identifier
      # An identifier of the common format, which is a sigil and a string.
      #
      # The string is a localpart and a server name where the kind of identifier says so.
      class Generic
        # The bytes an identifier may run to, including its sigil and server name.
        LENGTH = 255

        # The code points a localpart never holds, whichever kind it belongs to.
        FORBIDDEN = /[:\u0000]/

        class << self
          # @parameter string [String] the identifier to read.
          # @returns [Generic] the identifier it names.
          # @raises [InvalidIdentifierError] if it is not one.
          def parse(string)
            self.new(*self.split(string))
          end

          # The sigil taken off, and the localpart taken up to the first colon.
          #
          # A localpart never holds a colon, so the rest of the string is the server name.
          #
          # @parameter string [String] the identifier to split.
          # @returns [Array(String, String | nil)] the localpart and the server name.
          # @raises [InvalidIdentifierError] if the sigil is not ours.
          def split(string)
            unless string.start_with?(self::SIGIL)
              raise InvalidIdentifierError, "#{string.inspect} is not #{self.name}, whose sigil is #{self::SIGIL.inspect}!"
            end

            localpart, separator, server_name = string[1..].partition(":")

            [localpart, separator.empty? ? nil : server_name]
          end

          # @parameter value [String | Generic] the identifier, however it was given.
          # @returns [Generic] the identifier, parsed if it was not one already.
          def for(value)
            value.is_a?(self) ? value : self.parse(value.to_s)
          end

          # @parameter string [String] the identifier to judge.
          # @returns [Boolean] whether it is one.
          def valid?(string)
            self.parse(string)

            true
          rescue InvalidIdentifierError
            false
          end
        end

        # @parameter localpart [String] the part between the sigil and the server name.
        # @parameter server_name [String | ServerName | nil] the server which allocated it.
        # @raises [InvalidIdentifierError] if they do not make one of these.
        def initialize(localpart, server_name = nil)
          @localpart = localpart
          @server_name = server_name && ServerName.for(server_name)

          self.validate
        end

        # @attribute [String] the part between the sigil and the server name.
        attr :localpart

        # @attribute [ServerName | nil] the server which allocated it, where the grammar carries one.
        attr :server_name

        # @returns [String] the sigil this kind of identifier carries.
        def sigil
          self.class::SIGIL
        end

        # What every kind of identifier promises, which subclasses add their own grammar to.
        #
        # @raises [InvalidIdentifierError] if the localpart or the length is wrong.
        def validate
          if FORBIDDEN.match?(@localpart)
            raise InvalidIdentifierError, "A localpart holds neither a colon nor NUL, so #{@localpart.inspect} is not one!"
          end

          unless @localpart.b.force_encoding(::Encoding::UTF_8).valid_encoding?
            raise InvalidIdentifierError, "A localpart is valid UTF-8, so #{@localpart.inspect} is not one!"
          end

          unless self.to_s.bytesize <= LENGTH
            raise InvalidIdentifierError, "#{self.to_s.inspect} is #{self.to_s.bytesize} bytes, which is longer than #{LENGTH}!"
          end
        end

        # Insist on the server name this kind of identifier cannot do without.
        #
        # @raises [InvalidIdentifierError] if it has none.
        def require_server_name
          unless @server_name
            raise InvalidIdentifierError, "#{self.class} carries a server name, and #{self.to_s.inspect} has none!"
          end
        end

        def to_s
          "#{self.sigil}#{[@localpart, @server_name].compact.join(":")}"
        end

        alias to_str to_s

        def ==(other)
          other.class == self.class and other.to_s == self.to_s
        end

        alias eql? ==

        def hash
          [self.class, self.to_s].hash
        end

        def inspect
          "\#<#{self.class} #{self}>"
        end
      end
    end
  end
end
