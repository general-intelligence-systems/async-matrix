# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "readers"

module Async
  module Matrix
    module Events
      module Captions
        def format = @value[:format]

        def formatted_body = @value[:formatted_body]
      end

      module Filename
        def filename = @value[:filename]
      end

      module Relates
        extend Readers

        reads "m.relates_to"
      end

      module Attachment
        def url = @value[:url]

        def file = @value[:file]

        def info = @value[:info]
      end
    end
  end
end
