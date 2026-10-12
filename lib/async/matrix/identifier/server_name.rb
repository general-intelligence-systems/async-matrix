# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "../error"

module Async
  module Matrix
    module Identifier
      # The name of a homeserver, which is a host and an optional port.
      #
      # A host is a dotted quad, an IPv6 literal in brackets, or a DNS name.
      class ServerName
        # The grammar the appendices give, whose alternatives are tried in the order they are written.
        PATTERN = /
          \A
          (?:
            (?<ipv4>\d{1,3}(?:\.\d{1,3}){3})         # IPv4address
            |\[(?<ipv6>[0-9A-Fa-f:.]{2,45})\]        # "[" IPv6address "]"
            |(?<dns>[0-9A-Za-z\-.]{1,255})           # dns-name
          )
          (?::(?<port>\d{1,5}))?                     # [ ":" port ]
          \z
        /x

        class << self
          # @parameter string [String] the name to read.
          # @returns [ServerName] the name it holds.
          # @raises [InvalidIdentifierError] if it is not one.
          def parse(string)
            match = PATTERN.match(string)

            unless match
              raise InvalidIdentifierError, "#{string.inspect} is not a server name!"
            end

            self.new(match[:ipv4] || match[:ipv6] || match[:dns], match[:port]&.to_i, literal: !match[:dns])
          end

          # @parameter value [String | ServerName] the name, however it was given.
          # @returns [ServerName] the name, parsed if it was not one already.
          def for(value)
            value.is_a?(self) ? value : self.parse(value.to_s)
          end

          # @parameter string [String] the name to judge.
          # @returns [Boolean] whether it is one.
          def valid?(string)
            PATTERN.match?(string)
          end
        end

        # @parameter host [String] the host, without the brackets an IPv6 literal is written in.
        # @parameter port [Integer | nil] the port, where one was given.
        # @parameter literal [Boolean] whether the host is an address rather than a name.
        def initialize(host, port = nil, literal: false)
          @host = host
          @port = port
          @literal = literal
        end

        # @attribute [String] the host, without the brackets an IPv6 literal is written in.
        attr :host

        # @attribute [Integer | nil] the port, where one was given.
        attr :port

        # @returns [Boolean] whether the host is an address rather than a name.
        def literal?
          @literal
        end

        # @returns [Boolean] whether the host is an IPv6 literal, which is written in brackets.
        def bracketed?
          @literal and @host.include?(":")
        end

        def to_s
          [self.bracketed? ? "[#{@host}]" : @host, @port].compact.join(":")
        end

        alias to_str to_s

        def ==(other)
          other.is_a?(ServerName) and other.to_s == self.to_s
        end

        alias eql? ==

        def hash
          self.to_s.hash
        end

        def inspect
          "\#<#{self.class} #{self}>"
        end
      end
    end
  end
end
