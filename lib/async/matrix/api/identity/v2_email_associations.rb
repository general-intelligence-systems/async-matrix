# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "../../content"
require_relative "../../paths"
require_relative "../../representation"
require_relative "../../versioned"

module Async
  module Matrix
    module Identity
      # A validation session.
      class Validation < Representation
        include Versioned

        # @returns [String] the session, which the submission and the binding both quote.
        def sid
          self.value[:sid]
        end
      end

      # Whether a token was accepted.
      class Submission < Representation
        include Versioned

        # @returns [Boolean] whether it was.
        def success?
          self.value[:success]
        end
      end

      # Validating an email address.
      class V2EmailAssociations
        include Versioned

        # @parameter parent [Async::REST::Resource] the resource to derive from.
        # @returns [V2EmailAssociations] the validations.
        def self.for(parent)
          self.new(parent)
        end

        # @parameter resource [Async::REST::Resource] the resource to make requests against.
        def initialize(resource)
          @resource = resource
        end

        # @attribute [Async::REST::Resource] the resource requests are made against.
        attr :resource

        # Ask the server to send a token to the address.
        #
        # @parameter client_secret [String] a secret of the client's own, quoted back with the token.
        # @parameter email [String] the address to validate.
        # @parameter send_attempt [Integer] the attempt, which the server sends again only when it rises.
        # @parameter options [Hash] the rest the specification allows, e.g. `next_link:`.
        # @returns [Validation] the session the validation runs in.
        def email_request_token_v2(client_secret, email, send_attempt: 1, **options)
          payload = {client_secret: client_secret, email: email, send_attempt: send_attempt, **options}

          api::Validation.post(@resource.with(path: "#{IDENTITY_V2}/validate/email/requestToken"), payload)
        end

        # Submit a token by following the link in the message.
        #
        # The server answers with a page rather than a document.
        #
        # @parameter sid [String] the session.
        # @parameter client_secret [String] the secret the session was opened with.
        # @parameter token [String] the token which was sent.
        # @returns [Content] the page.
        def email_submit_token_get_v2(sid, client_secret, token)
          parameters = {sid: sid, client_secret: client_secret, token: token}

          api::Content.get(@resource.with(path: "#{IDENTITY_V2}/validate/email/submitToken", parameters: parameters))
        end

        # Submit a token, which is what a client does with one the user typed.
        #
        # @parameter sid [String] the session.
        # @parameter client_secret [String] the secret the session was opened with.
        # @parameter token [String] the token which was sent.
        # @returns [Submission] whether it was accepted.
        def email_submit_token_post_v2(sid, client_secret, token)
          payload = {sid: sid, client_secret: client_secret, token: token}

          api::Submission.post(@resource.with(path: "#{IDENTITY_V2}/validate/email/submitToken"), payload)
        end

        def inspect
          "\#<#{self.class}>"
        end
      end
    end
  end
end
