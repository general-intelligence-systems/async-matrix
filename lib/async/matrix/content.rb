# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/rest/representation"

require_relative "wrapper/content"

module Async
  module Matrix
    # The bytes of a file, rather than a document describing one.
    #
    # Building this reads the bytes, so a large file is asked for with a block instead.
    class Content < Async::REST::Representation[Wrapper::Content]
      # @returns [String] the bytes themselves.
      def bytes
        self.value
      end

      # @returns [String | nil] what the homeserver says the bytes are, e.g. `text/plain`.
      def content_type
        self.metadata["content-type"]
      end

      # The name the homeserver suggests for the file, where it suggests one.
      #
      # @returns [String | nil] the `content-disposition` header, which carries the name.
      def content_disposition
        self.metadata["content-disposition"]
      end

      # @returns [Integer] how many bytes there are.
      def size
        self.value.bytesize
      end
    end

    # The answer to bytes sent, which is a document rather than bytes.
    class Uploaded < Async::REST::Representation[Wrapper::Upload]
    end
  end
end
