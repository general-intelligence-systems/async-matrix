# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"

# Required before the wrapper: `Async::REST::Wrapper::Generic` names `Protocol::HTTP::Body::Wrapper` as it is defined, without requiring it itself.
require "protocol/http/body/wrapper"

require "async/rest/wrapper/generic"

require_relative "../error"
require_relative "../failure"

module Async
  module Matrix
    module Wrapper
      # The wrapper for the two part answer a federated media endpoint sends.
      #
      # The first part describes the file and the second part is the file, or says where it is.
      class Multipart < ::Async::REST::Wrapper::Generic
        # The media type the answer is sent as.
        CONTENT_TYPE = "multipart/mixed"

        # What separates the headers of a part from its body, and one line from the next.
        BREAK = "\r\n\r\n"

        NEWLINE = "\r\n"

        # The boundary a response declares, which is what its parts are separated by.
        #
        # @parameter response [Protocol::HTTP::Response] the response to read.
        # @returns [String | nil] the boundary, or nil where the response declares none.
        def self.boundary_for(response)
          content_type = response.headers["content-type"]

          if content_type.nil? or !content_type.start_with?(CONTENT_TYPE)
            nil
          else
            content_type[/boundary=("?)([^";]+)\1/, 2]
          end
        end

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

        # Ask for the two part answer, and send nothing.
        #
        # @parameter request [Protocol::HTTP::Request] the request to prepare.
        # @parameter payload [Nil] nothing: these endpoints only ever answer.
        def prepare_request(request, payload)
          request.headers["accept"] ||= CONTENT_TYPE
        end

        # Raise if the server refused, and otherwise parse the parts.
        #
        # A refusal is JSON rather than multipart, so it is read as a refusal.
        #
        # @parameter request [Protocol::HTTP::Request] the request that was made.
        # @parameter response [Protocol::HTTP::Response] the response that was received.
        # @returns [Protocol::HTTP::Response] the response.
        # @raises [RequestError] if the response was not successful.
        def process_response(request, response)
          unless response.success?
            failure = Failure.for(response)

            raise RequestError.new(response.status, failure&.errcode, failure&.message)
          end

          self.wrap_response(response)
        end

        # Wrap the body in the parser, where the response is in two parts.
        #
        # @parameter response [Protocol::HTTP::Response] the response to wrap.
        # @returns [Protocol::HTTP::Response] the response.
        def wrap_response(response)
          boundary = self.class.boundary_for(response)

          if response.body and boundary
            response.body = Parser.new(response.body, boundary)
          end

          response
        end

        # Reads the two parts, rather than the bytes they are written as.
        class Parser < ::Protocol::HTTP::Body::Wrapper
          # @parameter body [Protocol::HTTP::Body::Readable] the body to read.
          # @parameter boundary [String] what the parts are separated by.
          def initialize(body, boundary)
            super(body)

            @boundary = boundary
          end

          # @returns [Hash] the file, and what the first part says about it.
          def join
            Multipart.parse(super, @boundary)
          end
        end

        class << self
          # The parts of a multipart body, as one document.
          #
          # @parameter bytes [String] the body which was read.
          # @parameter boundary [String] what the parts are separated by.
          # @returns [Hash] the metadata, the bytes, and where they were if they were elsewhere.
          def parse(bytes, boundary)
            parts = self.parts(bytes, boundary)

            described, content = parts

            {
              metadata: self.document(described),
              content_type: content&.dig(:headers, "content-type"),
              content_disposition: content&.dig(:headers, "content-disposition"),
              location: content&.dig(:headers, "location"),
              bytes: content&.fetch(:body),
            }
          end

          # The parts a body holds, each its headers and its body.
          #
          # The boundary is chosen by the sender so as not to appear within a part.
          #
          # @parameter bytes [String] the body which was read.
          # @parameter boundary [String] what the parts are separated by.
          # @returns [Array(Hash)] the parts, in the order they were sent.
          def parts(bytes, boundary)
            bytes.to_s.split("--#{boundary}").filter_map do |chunk|
              trimmed = chunk.delete_prefix(NEWLINE)

              if trimmed.empty? or trimmed.start_with?("--")
                nil
              else
                self.part(trimmed)
              end
            end
          end

          # One part, split into what describes it and what it is.
          #
          # @parameter chunk [String] the part, headers and all.
          # @returns [Hash] its headers, and its body.
          def part(chunk)
            headers, _, body = chunk.partition(BREAK)

            {headers: self.headers(headers), body: body.delete_suffix(NEWLINE)}
          end

          # @parameter text [String] the header lines of a part.
          # @returns [Hash] the headers, by lowercased name.
          def headers(text)
            text.split(NEWLINE).filter_map do |line|
              name, separator, value = line.partition(":")

              if separator.empty?
                nil
              else
                [name.strip.downcase, value.strip]
              end
            end.to_h
          end

          # @parameter part [Hash | nil] the part which describes the file.
          # @returns [Hash] what it says, which is an empty document where it says nothing.
          def document(part)
            if part.nil? or part[:body].to_s.empty?
              {}
            else
              ::JSON.parse(part[:body], symbolize_names: true)
            end
          end
        end
      end
    end
  end
end
