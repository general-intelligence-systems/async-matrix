# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# Required before the wrapper: `Async::REST::Wrapper::Generic` names `Protocol::HTTP::Body::Wrapper` as it is defined, without requiring it itself.
require "protocol/http/body/buffered"
require "protocol/http/body/wrapper"

require "async/rest/wrapper/generic"

require_relative "../error"
require_relative "../failure"
require_relative "json"

module Async
  module Matrix
    module Wrapper
      # The wrapper for the bytes a media endpoint sends and receives.
      #
      # A media body is sent as it is and read back as it arrives. A refusal is still JSON.
      class Content < ::Async::REST::Wrapper::Generic
        # Make the request, once.
        #
        # Waiting out a rate limit belongs below the resource, as it does for {JSON}.
        #
        # @parameter resource [Async::REST::Resource] the resource to make the request against.
        # @parameter request [Protocol::HTTP::Request] the request to make.
        # @returns [Protocol::HTTP::Response] the response.
        def response_for(resource, request)
          resource.call(request)
        end

        # Send the bytes as they are, where there are any.
        #
        # The type is the caller's to set, on the resource. A download sends nothing.
        #
        # @parameter request [Protocol::HTTP::Request] the request to prepare.
        # @parameter payload [String | nil] the bytes to send.
        def prepare_request(request, payload)
          if payload
            request.body = ::Protocol::HTTP::Body::Buffered.new([payload])
          end
        end

        # Raise if the homeserver refused, and otherwise leave the body alone.
        #
        # @parameter request [Protocol::HTTP::Request] the request that was made.
        # @parameter response [Protocol::HTTP::Response] the response that was received.
        # @returns [Protocol::HTTP::Response] the response.
        # @raises [RequestError] if the response was not successful.
        def process_response(request, response)
          super

          unless response.success?
            failure = Failure.for(response)

            raise RequestError.new(response.status, failure&.errcode, failure&.message)
          end

          response
        end
      end

      # The wrapper for bytes sent to a media endpoint which answers with a document.
      #
      # Bytes go up and JSON comes back, so the answer is read as {JSON} reads it.
      class Upload < JSON
        # Send the bytes as they are, and ask for a document back.
        #
        # The type is the caller's to set, on the resource, since only it knows what the bytes are.
        #
        # @parameter request [Protocol::HTTP::Request] the request to prepare.
        # @parameter payload [String | nil] the bytes to send.
        def prepare_request(request, payload)
          request.headers["accept"] ||= self.content_type

          if payload
            request.body = ::Protocol::HTTP::Body::Buffered.new([payload])
          end
        end
      end
    end
  end
end
