# frozen_string_literal: true

require "async/matrix"
require "async/http/internet"
require "multi_json"
require "uri"

module Matrix
  module Homeserver
    VERSION = "v1.19"

    INTERNET = Async::HTTP::Internet.new

    WELL_KNOWN = "/.well-known/matrix/client"

    SERVER_NAME = /\A[A-Za-z0-9.\-]+(:\d+)?\z/

    DISPLAY_NAME = "async-matrix web-client"

    HOMEPAGE = "https://github.com/general-intelligence-systems/async-matrix"

    module_function

    def client(base_url)
      Async::Matrix::ClientServer::Client[VERSION].open(base_url)
    end

    def with_client(base_url)
      Sync do
        client = self.client(base_url)

        begin
          yield client
        ensure
          client.close
        end
      end
    rescue StandardError
      nil
    end

    def resolve(input, autodiscovery: true)
      value = input.to_s.strip

      if autodiscovery
        self.resolve_server_name(value)
      else
        self.sanitize_url(value)
      end
    end

    def resolve_server_name(name)
      unless SERVER_NAME.match?(name)
        nil
      else
        self.well_known("https://#{name}") || "https://#{name}"
      end
    end

    def sanitize_url(url)
      parsed = URI.parse(url)

      if parsed.is_a?(URI::HTTP) && !parsed.host.to_s.empty?
        parsed.to_s.chomp("/")
      else
        nil
      end
    rescue URI::InvalidURIError
      nil
    end

    def well_known(origin)
      body = Sync do
        response = INTERNET.get("#{origin}#{WELL_KNOWN}", { "accept" => "application/json" })

        begin
          response.status.between?(200, 299) ? MultiJson.load(response.read) : nil
        ensure
          response.close
        end
      end

      self.sanitize_url(body.dig("m.homeserver", "base_url").to_s)
    rescue StandardError
      nil
    end

    def login_flows(base_url)
      self.with_client(base_url){|client| client.get_login_flows.types} || []
    end

    def identity_providers(base_url)
      flows = self.with_client(base_url){|client| client.get_login_flows.flows} || []
      sso = flows.find{|flow| flow["type"] == "m.login.sso"}

      Array(sso&.fetch("identity_providers", nil))
    end

    def oauth?(base_url)
      !self.with_client(base_url){|client| client.oauth_server_metadata.get_auth_metadata}.nil?
    end

    def password_login(base_url, user, password, device_id)
      self.with_client(base_url) do |client|
        self.as_session(client.login(user, password, device_id: device_id, initial_device_display_name: DISPLAY_NAME))
      end
    end

    def token_login(base_url, token, device_id)
      self.with_client(base_url) do |client|
        self.as_session(client.login_with_token(token, device_id: device_id, initial_device_display_name: DISPLAY_NAME))
      end
    end

    def sso_url(base_url, redirect_url, provider: nil)
      self.with_client(base_url) do |client|
        if provider.to_s.empty?
          client.sso_login_url(redirect_url)
        else
          client.sso_login_url(redirect_url, idp_id: provider)
        end
      end
    end

    def as_session(login)
      {
        "access_token" => login.access_token,
        "user_id"      => login.user_id,
        "device_id"    => login.device_id,
      }
    end

    def begin_authorization(base_url, redirect_uri)
      self.with_client(base_url) do |client|
        server = client.authorization_server

        begin
          registration = server.register(**self.client_metadata(redirect_uri))

          verifier = Async::Matrix::OAuth::Verifier.generate
          state = Async::Matrix::OAuth::AuthorizationServer.state
          device_id = Async::Matrix::OAuth::AuthorizationServer.device_id

          url = server.authorization_url(
            client_id:    registration.client_id,
            redirect_uri: redirect_uri,
            verifier:     verifier,
            scope:        Async::Matrix::OAuth::AuthorizationServer.scope(device_id),
            state:        state,
          )

          {
            "url"       => url,
            "client_id" => registration.client_id,
            "state"     => state,
            "verifier"  => verifier.verifier,
            "device_id" => device_id,
            "issuer"    => server.metadata.issuer,
            "redirect"  => redirect_uri,
          }
        ensure
          server.close
        end
      end
    end

    def client_metadata(redirect_uri)
      {
        client_name:                DISPLAY_NAME,
        client_uri:                 HOMEPAGE,
        application_type:           self.application_type(redirect_uri),
        grant_types:                ["authorization_code", "refresh_token"],
        response_types:             ["code"],
        redirect_uris:              [redirect_uri],
        token_endpoint_auth_method: "none",
      }
    end

    def application_type(redirect_uri)
      if redirect_uri.to_s.start_with?("https://")
        "web"
      else
        "native"
      end
    end

    def complete_authorization(base_url, pending, code)
      self.with_client(base_url) do |client|
        server = client.authorization_server

        begin
          tokens = server.exchange(
            code,
            client_id:    pending["client_id"],
            redirect_uri: pending["redirect"],
            verifier:     Async::Matrix::OAuth::Verifier.new(pending["verifier"]),
          )

          self.whoami(base_url, tokens)
        ensure
          server.close
        end
      end
    end

    def whoami(base_url, tokens)
      self.with_client(base_url) do |client|
        answer = client.authenticated(tokens.access_token).get_token_owner

        {
          "access_token"  => tokens.access_token,
          "refresh_token" => tokens.refresh_token,
          "expires_in_ms" => tokens.expires_in_ms,
          "user_id"       => answer.user_id,
          "device_id"     => answer.device_id,
        }
      end
    end
  end
end
