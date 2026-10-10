# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

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

      module Attachment
        def url = @value[:url]

        def file = @value[:file]

        def info = @value[:info]
      end
    end
  end
end
