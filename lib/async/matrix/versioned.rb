# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

module Async
	module Matrix
		# Included into every class which can be built for a specific specification version.
		#
		# A versioned class knows which generated API it belongs to, which is how one class finds
		# another of the same version: a `v1.5` client builds `v1.5` rooms, and nothing can mix
		# versions by accident. A class which was not built for a version resolves its peers to the
		# unversioned classes in {Async::Matrix} itself.
		module Versioned
			module ClassMethods
				# @returns [Module] the generated API this class belongs to, or {Async::Matrix}.
				def api
					if self.const_defined?(:API)
						self::API
					else
						Matrix
					end
				end
				
				# The specification version this class implements.
				#
				# Deliberately not `VERSION`: {Async::Matrix::VERSION} is the gem's own version, and an
				# unversioned class resolves its api to {Async::Matrix}.
				#
				# @returns [String | nil] the version, or nil if this class is not versioned.
				def version
					api = self.api
					
					api::SPEC_VERSION if api.const_defined?(:SPEC_VERSION, false)
				end
			end
			
			def self.included(klass)
				klass.extend(ClassMethods)
			end
			
			# @returns [Module] the generated API this instance's class belongs to.
			def api
				self.class.api
			end
			
			# @returns [String | nil] the specification version of this instance's class.
			def version
				self.class.version
			end
		end
	end
end
