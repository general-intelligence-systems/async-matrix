# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/rest/representation"

require_relative "redacted"
require_relative "wrapper/json"

module Async
  module Matrix
    # The base representation for all Matrix responses.
    class Representation < Async::REST::Representation[Wrapper::JSON]
      include Redacted
    end
  end
end
