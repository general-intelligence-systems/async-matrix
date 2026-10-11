# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Nathan K.

require "protocol/url/encoding"

require "async/matrix/operations_context"

# Cases for the single sign on redirects, layered by version.

module Async
  module Matrix
    module Testing
      module Abstract
        module ClientServer
          module SSOLoginRedirect
            # No changes in v1.19.
            module V1_19
            end

            # No changes in v1.18.
            module V1_18
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

            # v1.1 added the single sign on redirects.
            module V1_1
              def self.included(base)
                base.let(:redirect_url){"http://127.0.0.1:9999/callback"}

                # The user's browser follows this, so it has to name the homeserver.
                base.it "can redirectToSSO" do
                  url = client.sso_login_redirect.redirect_to_sso(redirect_url)

                  expect(url).to be(:start_with?, Async::Matrix::HOMESERVER)
                  expect(url).to be(:include?, "/_matrix/client/v3/login/sso/redirect?")
                  expect(url).to be(:include?, ::Protocol::URL::Encoding.escape(redirect_url))
                end

                base.it "can redirectToIdP" do
                  url = client.sso_login_redirect.redirect_to_idp("a-provider", redirect_url)

                  expect(url).to be(:include?, "/_matrix/client/v3/login/sso/redirect/a-provider?")
                  expect(url).to be(:include?, ::Protocol::URL::Encoding.escape(redirect_url))
                end

                base.it "carries the action when the user has chosen one" do
                  url = client.sso_login_redirect.redirect_to_sso(redirect_url, action: "login")

                  expect(url).to be(:include?, "action=login")
                end

                # Nothing is sent: the endpoint answers a browser with a redirect, so the URL is built.
                base.it "omits an action which was not chosen" do
                  url = client.sso_login_redirect.redirect_to_sso(redirect_url)

                  expect(url).not.to be(:include?, "action")
                end

                base.it "escapes a provider which is not a bare word" do
                  url = client.sso_login_redirect.redirect_to_idp("a/provider", redirect_url)

                  expect(url).to be(:include?, "redirect/a%2Fprovider")
                end

                # The one builder both redirects go through, which has to name the homeserver.
                base.it "builds an absolute url against the homeserver" do
                  url = client.sso_login_redirect.url_for("/_matrix/client/v3/login/sso/redirect", redirectUrl: redirect_url)

                  expect(url).to be(:start_with?, Async::Matrix::HOMESERVER)
                end

                base.it "drops a parameter which was not given" do
                  url = client.sso_login_redirect.url_for("/x", redirectUrl: redirect_url, action: nil)

                  expect(url).not.to be(:include?, "action")
                end

                # One method over both operations, so the caller need not know which endpoint an IdP choice implies.
                base.it "sends the user to any provider when none was chosen" do
                  expect(client.sso_login_url(redirect_url)).to be == client.sso_login_redirect.redirect_to_sso(redirect_url)
                end

                base.it "sends the user to the provider which was chosen" do
                  chosen = client.sso_login_url(redirect_url, idp_id: "a-provider")

                  expect(chosen).to be == client.sso_login_redirect.redirect_to_idp("a-provider", redirect_url)
                  expect(chosen).to be(:include?, "redirect/a-provider")
                end

                # The homeserver chooses between them, so the client offers both forms.
                base.it "reports the providers the homeserver offers" do
                  expect(unauthenticated.get_login_flows.identity_providers).to be_a(Array)
                end
              end
            end

            # The cases required at the version under test.
            CASES = Sus::Shared("sso login redirect cases") do
              Async::Matrix::Versions.layers_for(Async::Matrix::TEST_VERSION).each do |name|
                if SSOLoginRedirect.const_defined?(name, false)
                  include SSOLoginRedirect.const_get(name, false)
                end
              end
            end
          end
        end
      end
    end
  end
end
