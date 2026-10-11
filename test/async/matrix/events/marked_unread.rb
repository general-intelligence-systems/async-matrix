# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/client_context"
require "async/matrix/events_context"

describe Async::Matrix::Events::MarkedUnread do
  include Async::Matrix::ClientContext
  include Async::Matrix::EventsContext
end
