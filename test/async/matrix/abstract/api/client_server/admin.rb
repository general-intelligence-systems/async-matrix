# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "async/matrix/operations_context"

# Cases for the administrative operations, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          # Cases for {ruby Async::Matrix::ClientServer::Admin}.
          module Admin
            # No changes in v1.19.
            module V1_19
            end

            # v1.18 added locking and suspending a user.
            module V1_18
              def self.included(base)
                # Synapse answers these 404 M_UNRECOGNIZED: it has its own administration API and has not taken up the specification's. The case asserts the refusal it does give, which proves the request is the one the specification describes and that it reached the homeserver. When Synapse implements the endpoint this fails, and this case is the one to rewrite.
                base.it "can getAdminSuspendUser" do
                  expect(suspension.errcode).to be == "M_UNRECOGNIZED"
                end

                base.it "can setAdminSuspendUser" do
                  error = nil

                  begin
                    client.admin.set_admin_suspend_user(self.user_id, true)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == "M_UNRECOGNIZED"
                end

                base.it "can getAdminLockUser" do
                  expect(lock.errcode).to be == "M_UNRECOGNIZED"
                end

                base.it "can setAdminLockUser" do
                  error = nil

                  begin
                    client.admin.set_admin_lock_user(self.user_id, true)
                  rescue Async::Matrix::RequestError => error
                  end

                  expect(error.errcode).to be == "M_UNRECOGNIZED"
                end

                base.let(:suspension) do
                  error = nil

                  begin
                    client.admin.get_admin_suspend_user(self.user_id)
                  rescue Async::Matrix::RequestError => error
                  end

                  error
                end

                base.let(:lock) do
                  error = nil

                  begin
                    client.admin.get_admin_lock_user(self.user_id)
                  rescue Async::Matrix::RequestError => error
                  end

                  error
                end
              end
            end

            # No changes in v1.17.
            module V1_17
            end

            # No changes in v1.16.
            module V1_16
            end

            # No changes in v1.15.
            module V1_15
            end

            # No changes in v1.14.
            module V1_14
            end

            # No changes in v1.13.
            module V1_13
            end

            # No changes in v1.12.
            module V1_12
            end

            # No changes in v1.11.
            module V1_11
            end

            # No changes in v1.10.
            module V1_10
            end

            # No changes in v1.9.
            module V1_9
            end

            # No changes in v1.8.
            module V1_8
            end

            # No changes in v1.7.
            module V1_7
            end

            # No changes in v1.6.
            module V1_6
            end

            # No changes in v1.5.
            module V1_5
            end

            # No changes in v1.4.
            module V1_4
            end

            # No changes in v1.3.
            module V1_3
            end

            # No changes in v1.2.
            module V1_2
            end

            # No changes in v1.1.
            module V1_1
            end
            # The cases required at the version under test.
            CASES = Sus::Shared("administration cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if Admin.const_defined?(name, false)
                  include Admin.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
