# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "matrix/version"
require_relative "matrix/error"
require_relative "matrix/endpoint"
require_relative "matrix/notifier"
require_relative "matrix/client"
require_relative "matrix/server"
require_relative "matrix/connection"
require_relative "matrix/stream"

require_relative "matrix/application_service/event"
require_relative "matrix/application_service/transaction"
require_relative "matrix/application_service/error_response"
require_relative "matrix/application_service/transaction_store"
require_relative "matrix/application_service/dispatcher"
require_relative "matrix/application_service/config"
require_relative "matrix/application_service/server"

# @namespace
module Async
	# @namespace
	module Matrix
	end
end
