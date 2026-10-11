# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "async/matrix/client_context"
require "async/matrix/operations_context"

require_relative "../../abstract/api/client_server/pushrules"

describe Async::Matrix::ClientServer::PushRules do
  include Async::Matrix::ClientContext
  include Async::Matrix::OperationsContext

  let(:rules) {client.pushrules}

  # Every version answers for the whole set, so the method is on the class rather than in a layer.
  it "can getPushRules" do
    expect(rules.get_push_rules.global).to be(:include?, :underride)
  end

  # The other eight operations take `scope` positionally through v1.11, and drop it from v1.12 on, so their cases are layered by the version which carries each signature:
  include Async::Matrix::Testing::Abstract::ClientServer::PushRules::CASES
end
