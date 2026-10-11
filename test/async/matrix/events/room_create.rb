# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/events_context"

require_relative "../abstract/events/room_create"

describe Async::Matrix::Events::RoomCreate do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Events::RoomCreate::CASES
end
