# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require_relative "paths"
require_relative "representation"

module Async
	module Matrix
		# The response to logging in.
		class Login < Representation
			# @returns [String] the access token to authenticate subsequent requests with.
			def access_token
				self.value[:access_token]
			end
			
			# @returns [String] the fully qualified ID of the user that logged in.
			def user_id
				self.value[:user_id]
			end
			
			# @returns [String] the ID of the device that was created by this login.
			def device_id
				self.value[:device_id]
			end
		end
		
		# The identity associated with an access token.
		class Whoami < Representation
			# @returns [String] the fully qualified ID of the authenticated user.
			def user_id
				self.value[:user_id]
			end
			
			# @returns [String | nil] the ID of the authenticated device.
			def device_id
				self.value[:device_id]
			end
			
			# @returns [Boolean] whether the authenticated user is a guest.
			def guest?
				self.value[:is_guest] || false
			end
		end
	end
end
