# frozen_string_literal: true

require "async/http/internet"
require "multi_json"
require "uri"

module Matrix
  module Homeserver
    INTERNET = Async::HTTP::Internet.new

    WELL_KNOWN = "/.well-known/matrix/client"

    SERVER_NAME = /\A[A-Za-z0-9.\-]+(:\d+)?\z/

    SSO_PATH = "/_matrix/client/v3/login/sso/redirect"

    LOGIN_PATH = "/_matrix/client/v3/login"

    module_function

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
      body = self.get("#{origin}#{WELL_KNOWN}")

      self.sanitize_url(body.dig("m.homeserver", "base_url").to_s)
    rescue StandardError
      nil
    end

    def flows(base_url)
      body = self.get("#{base_url}#{LOGIN_PATH}")

      Array(body&.fetch("flows", nil)).filter_map{|flow| flow["type"]}
    end

    def identity_providers(base_url)
      body = self.get("#{base_url}#{LOGIN_PATH}")
      flow = Array(body&.fetch("flows", nil)).find{|entry| entry["type"] == "m.login.sso"}

      Array(flow&.fetch("identity_providers", nil))
    end

    def sso_url(base_url, redirect_url, provider: nil)
      query = URI.encode_www_form(redirectUrl: redirect_url)

      if provider.to_s.empty?
        "#{base_url}#{SSO_PATH}?#{query}"
      else
        "#{base_url}#{SSO_PATH}/#{URI.encode_www_form_component(provider)}?#{query}"
      end
    end

    def password_login(base_url, user, password, device_id)
      self.login(
        base_url,
        type:       "m.login.password",
        identifier: { "type" => "m.id.user", "user" => user },
        password:   password,
        device_id:  device_id,
      )
    end

    def token_login(base_url, token, device_id)
      self.login(base_url, type: "m.login.token", token: token, device_id: device_id)
    end

    def login(base_url, **body)
      payload = body.transform_keys(&:to_s)
      payload["initial_device_display_name"] = "async-matrix web-client"

      self.post("#{base_url}#{LOGIN_PATH}", payload)
    end

    def get(url)
      Sync do
        response = INTERNET.get(url, { "accept" => "application/json" })

        self.read(response)
      end
    rescue StandardError
      nil
    end

    def post(url, payload)
      Sync do
        response = INTERNET.post(
          url,
          { "content-type" => "application/json", "accept" => "application/json" },
          [MultiJson.dump(payload)],
        )

        self.read(response)
      end
    rescue StandardError
      nil
    end

    def read(response)
      body = response.read

      if response.status.between?(200, 299)
        MultiJson.load(body)
      else
        nil
      end
    ensure
      response.close
    end
  end
end
