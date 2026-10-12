# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "generic"

module Async
  module Matrix
    module Identifier
      # A user, namespaced to the homeserver which allocated the account.
      class UserID < Generic
        SIGIL = "@"

        # The localpart the current specification allows, which is a subset of what older ones did.
        LOCALPART = /\A[a-z0-9.\-=_\/+]+\z/

        # The range outside which a localpart is not to be shown to a client except within an event.
        COMPLIANT = /\A[!-~]+\z/

        # The characters a mapped localpart can carry unescaped, which is the grammar less the escapes.
        MAPPED = /\A[a-z0-9.\-\/+]\z/

        class << self
          # A localpart made from a name a wider character set allows, by the algorithm the appendices suggest.
          #
          # @parameter string [String] the name to map.
          # @parameter server_name [String | ServerName] the server to namespace it to.
          # @parameter escape [Boolean] whether to keep case, by writing an upper case letter as `_` and the letter.
          # @returns [UserID] the user ID it maps onto.
          def mapped(string, server_name:, escape: false)
            localpart = string.to_s.dup.force_encoding(::Encoding::BINARY).each_byte.map do |byte|
              self.mapped_byte(byte, escape: escape)
            end

            self.new(localpart.join, server_name)
          end

          # @parameter byte [Integer] the byte to write.
          # @parameter escape [Boolean] whether to keep case, by writing an upper case letter as `_` and the letter.
          # @returns [String] what the byte is written as.
          def mapped_byte(byte, escape: false)
            character = byte.chr

            case character
            when "A".."Z"
              escape ? "_#{character.downcase}" : character.downcase
            when "_"
              escape ? "__" : "_"
            when MAPPED
              character
            else
              format("=%02x", byte)
            end
          end
        end

        # @returns [Boolean] whether the localpart is one only an older specification allowed.
        def historical?
          !LOCALPART.match?(@localpart)
        end

        # Whether a server may name this user outside an event.
        #
        # @returns [Boolean] whether the localpart is compliant.
        def compliant?
          COMPLIANT.match?(@localpart)
        end

        def validate
          super

          self.require_server_name
        end
      end
    end
  end
end
