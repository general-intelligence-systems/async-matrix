# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

# This summary paragraph is deliberately wrapped across
# two lines, which the cop forbids.
module Wrapped
end

# This module summary is far too long because it keeps going and going well past the ten words a module is allowed.
module TooLong
end

# Short summary.
module Fine
end

class Subject
  # Described in prose with no annotations at all, which the cop forbids in lib.
  def undocumented(value)
    value
  end

  # @parameter value [Integer] the value.
  # @returns [Integer] the value.
  def documented(value)
    value
  end

  # @parameter value [Integer] the summary of this annotation is wrapped
  #   across two lines, which the cop forbids.
  def wrapped_annotation(value)
    value
  end
end
