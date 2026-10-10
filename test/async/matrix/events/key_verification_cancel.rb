# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/events_context"

describe Async::Matrix::Events::KeyVerificationCancel do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext
end
