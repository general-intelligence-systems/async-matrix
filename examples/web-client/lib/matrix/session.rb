# frozen_string_literal: true

require "async/matrix"

require_relative "homeserver"

module Matrix
  module Session
    OAUTH_CLIENT = "oauth_client"

    module_function

    def remember_oauth_client!(homeserver_url, client_id, issuer, manage = nil)
      Models::Matrix::KV.set!(
        OAUTH_CLIENT,
        { "client_id" => client_id, "issuer" => issuer, "manage" => manage },
        homeserver_url,
      )
    end

    def oauth_client(credential)
      Models::Matrix::KV[OAUTH_CLIENT, credential.homeserver_url]
    end

    def forget_oauth_client!(credential)
      Models::Matrix::KV.unset!(OAUTH_CLIENT, credential.homeserver_url)
    end

    def expires_in_ms(credential)
      if credential.expires_at.nil?
        nil
      else
        remaining = credential.expires_at - (Time.now.to_f * 1000).to_i

        remaining.positive? ? remaining : 1
      end
    end

    def persist!(credential, credentials)
      unless credentials.access_token == credential.access_token
        credential.set(
          access_token:  credentials.access_token,
          refresh_token: credentials.refresh_token,
          expires_at:    credentials.expires_at && (credentials.expires_at.to_f * 1000).to_i,
        )
        credential.save_changes
      end
    end

    def client(credential)
      client = Homeserver.client(credential.homeserver_url)
      oauth = self.oauth_client(credential)

      if oauth
        refresher = Async::Matrix::OAuth::Issuer.new(client.authorization_server, oauth["client_id"])
      else
        refresher = client.refresh
      end

      credentials = Async::Matrix::Credentials.new(
        refresher,
        access_token:  credential.access_token,
        refresh_token: credential.refresh_token,
        expires_in_ms: self.expires_in_ms(credential),
      )

      client.with_credentials(credentials)
    end

    def open(credential)
      Sync do
        client = Homeserver.client(credential.homeserver_url)
        oauth = self.oauth_client(credential)
        server = oauth && client.authorization_server

        begin
          if server
            refresher = Async::Matrix::OAuth::Issuer.new(server, oauth["client_id"])
          else
            refresher = client.refresh
          end

          credentials = Async::Matrix::Credentials.new(
            refresher,
            access_token:  credential.access_token,
            refresh_token: credential.refresh_token,
            expires_in_ms: self.expires_in_ms(credential),
          )

          answer = yield client.with_credentials(credentials), credentials

          self.persist!(credential, credentials)

          answer
        ensure
          server&.close
          client.close
        end
      end
    end

    def renew!(credential)
      self.open(credential) do |_client, credentials|
        unless credentials.renewable?
          nil
        else
          credentials.renew!

          true
        end
      end
    rescue StandardError
      nil
    end

    def token_owner(credential)
      self.open(credential) do |client, _credentials|
        answer = client.get_token_owner

        { "user_id" => answer.user_id, "device_id" => answer.device_id }
      end
    rescue StandardError
      nil
    end

    def devices(credential)
      self.open(credential) do |client, _credentials|
        client.devices.get_devices.devices
      end
    rescue StandardError
      nil
    end

    def log_out!(credential, everywhere: false)
      self.open(credential) do |client, credentials|
        if self.oauth_client(credential)
          credentials.revoke!
        else
          everywhere ? client.logout_all : client.logout
        end
      end

      self.forget!(credential)

      true
    rescue StandardError
      self.forget!(credential)

      true
    end

    def forget!(credential)
      self.forget_oauth_client!(credential)
      Models::Matrix::KV.unset!(Models::Matrix::KV::SYNC_TOKEN)
      credential.destroy
    end

    def change_password!(credential, new_password, old_password, logout_devices: false)
      self.open(credential) do |client, _credentials|
        client.password_management.change_password(
          new_password,
          logout_devices: logout_devices,
          auth: self.password_auth(credential, old_password),
        )
      end

      true
    rescue StandardError
      nil
    end

    def deactivate!(credential, password, erase: false)
      self.open(credential) do |client, _credentials|
        client.account_deactivation.deactivate_account(
          auth: self.password_auth(credential, password),
          erase: erase,
        )
      end

      self.forget!(credential)

      true
    rescue StandardError
      nil
    end

    def password_auth(credential, password)
      {
        "type"       => "m.login.password",
        "identifier" => { "type" => "m.id.user", "user" => credential.matrix_user_id },
        "password"   => password,
      }
    end

    def register(base_url, username, password)
      Homeserver.with_client(base_url) do |client|
        answer = client.registration.register(username: username, password: password)

        {
          "access_token"  => answer.access_token,
          "refresh_token" => nil,
          "user_id"       => answer.user_id,
          "device_id"     => answer.device_id,
        }
      end
    end
  end
end
