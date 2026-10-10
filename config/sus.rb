# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

begin
	require "covered/sus"
	include Covered::Sus
rescue LoadError
	# Coverage is optional.
end
