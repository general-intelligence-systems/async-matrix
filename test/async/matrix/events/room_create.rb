# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/events_context"

require_relative "../abstract/events/room_create"

describe Async::Matrix::Events::RoomCreate do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext

  # The cases for the operations themselves, layered by the version which introduced each:
  include Async::Matrix::Testing::Abstract::Events::RoomCreate::CASES
end
