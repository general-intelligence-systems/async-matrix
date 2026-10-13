# frozen_string_literal: true

require "async/http/internet"

MAS_INTERNET = Async::HTTP::Internet.new

get "/" do
  pending = session.delete(:matrix_oidc)

  if params["error"]
    session[:matrix_login_error] =
      [params["error"], params["error_description"]].compact.reject(&:empty?).join(": ")
    redirect("/matrix/login", 303)
  end

  code = params["code"].to_s

  if pending.nil? || code.empty?
    session[:matrix_login_error] = "the sign-in attempt expired; start it again"
    redirect("/matrix/login", 303)
  end

  unless Rack::Utils.secure_compare(params["state"].to_s, pending["state"].to_s)
    session[:matrix_login_error] = "state did not match; the sign-in was not completed here"
    redirect("/matrix/login", 303)
  end

  tokens = mas_token_request(
    grant_type:    "authorization_code",
    code:          code,
    redirect_uri:  pending["redirect"],
    code_verifier: pending["verifier"],
  )

  if tokens.nil?
    session[:matrix_login_error] = "the homeserver rejected the authorization code"
    redirect("/matrix/login", 303)
  end

  whoami = mas_whoami(tokens["access_token"])

  if whoami.nil?
    session[:matrix_login_error] = "got a token but the homeserver would not identify it"
    redirect("/matrix/login", 303)
  end

  credential = Models::Matrix::Credential.first || Models::Matrix::Credential.new

  credential.set(
    homeserver_url: MATRIX_HOMESERVER,
    matrix_user_id: whoami["user_id"],
    device_id:      whoami["device_id"] || pending["device_id"],
    access_token:   tokens["access_token"],
    refresh_token:  tokens["refresh_token"],
    expires_at:     tokens["expires_in"] ? ((Time.now.to_i + tokens["expires_in"].to_i) * 1000) : nil,
  )
  credential.save_changes

  redirect("/matrix", 303)
end

helpers do
  def mas_token_request(**params)
    uri = "#{MAS_URL.chomp("/")}/oauth2/token"
    basic = Base64.strict_encode64("#{MAS_CLIENT_ID}:#{MAS_CLIENT_SECRET}")

    Sync do
      response = MAS_INTERNET.post(
        uri,
        {
          "authorization" => "Basic #{basic}",
          "content-type"  => "application/x-www-form-urlencoded",
          "accept"        => "application/json",
        },
        [URI.encode_www_form(params)],
      )

      begin
        body = response.read
        response.status.between?(200, 299) ? MultiJson.load(body) : nil
      ensure
        response.close
      end
    end
  rescue StandardError
    nil
  end

  def mas_whoami(access_token)
    Sync do
      response = MAS_INTERNET.get(
        "#{MATRIX_HOMESERVER.chomp("/")}/_matrix/client/v3/account/whoami",
        { "authorization" => "Bearer #{access_token}", "accept" => "application/json" },
      )

      begin
        body = response.read
        response.status.between?(200, 299) ? MultiJson.load(body) : nil
      ensure
        response.close
      end
    end
  rescue StandardError
    nil
  end
end
