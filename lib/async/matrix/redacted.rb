# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
  module Matrix
    # Keeps secrets out of `inspect`.
    module Redacted
      # The keys whose values are secrets.
      SECRET = [:access_token, :refresh_token, :client_secret, :password, :token].freeze

      # What a secret is shown as in place of its value.
      REDACTED = "[redacted]"

      # The value, with the value of every secret key replaced.
      #
      # @parameter value [Object] the value to redact.
      # @returns [Object] the value, with every secret replaced.
      def self.redact(value)
        case value
        when Hash
          value.to_h do |key, nested|
            if SECRET.include?(key)
              [key, REDACTED]
            else
              [key, self.redact(nested)]
            end
          end
        when Array
          value.map{|each| self.redact(each)}
        else
          value
        end
      end

      def inspect
        "\#<#{self.class} #{@resource.path.inspect} value=#{Redacted.redact(@value).inspect}>"
      end
    end
  end
end
