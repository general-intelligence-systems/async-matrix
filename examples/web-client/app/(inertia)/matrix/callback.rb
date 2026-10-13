# frozen_string_literal: true

# /matrix/callback — where the homeserver sends the browser back.
#
# NO __END__ AND NO PAGE. This only ever redirects, so it is a route without a component; the Vite
# plugin keys pages off the __END__ block, so leaving it out is what keeps this out of the page map.
#

# Where the homeserver sends the browser back, for both ways of leaving.
#
# Fractal runs a loopback HTTP server for this and closes it once the answer arrives
# (login/local_server.rs); a web client already has a URL the homeserver can reach, so this route is
# that server.
#
# OAuth 2.0 returns `code` and `state`, which are redeemed at the token endpoint with the PKCE
# verifier held in the session. The native SSO API returns a one-shot `loginToken`, traded through
# POST /login with m.login.token. Nothing is configured for either: the client is registered on the
# way out, and the token exchange is the gem's.
get "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    session[:matrix_login_error] = "the sign-in attempt expired; start it again"
    redirect("/matrix/login", 303)
  end

  if params["error"]
    session[:matrix_login_error] =
      [params["error"], params["error_description"]].compact.reject(&:empty?).join(": ")
    redirect("/matrix/login", 303)
  end

  pending = session.delete(:matrix_oauth)
  code = params["code"].to_s

  unless code.empty?
    if pending.nil?
      session[:matrix_login_error] = "the sign-in attempt expired; start it again"
      redirect("/matrix/login", 303)
    end

    # RFC 6749 asks the client to prove the redirect belongs to the request it made.
    unless Rack::Utils.secure_compare(params["state"].to_s, pending["state"].to_s)
      session[:matrix_login_error] = "state did not match; the sign-in was not completed here"
      redirect("/matrix/login", 303)
    end

    answer = Matrix::Homeserver.complete_authorization(base_url, pending, code)

    if answer.nil?
      session[:matrix_login_error] = "the authorization server rejected the code"
      redirect("/matrix/login", 303)
    end

    # The registered client outlives the flow: renewing and revoking an OAuth token both name the
    # client which was issued it, where a native session asks with the refresh token alone.
    Matrix::Session.remember_oauth_client!(base_url, pending["client_id"], pending["issuer"], pending["manage"])

    store_session(base_url, answer)

    redirect("/matrix/login/setup", 303)
  end

  token = params["loginToken"].to_s

  if token.empty?
    session[:matrix_login_error] = "the homeserver returned neither a code nor a login token"
    redirect("/matrix/login", 303)
  end

  answer = Matrix::Homeserver.token_login(base_url, token, matrix_device_id)

  if answer.nil?
    session[:matrix_login_error] = "the homeserver rejected the login token"
    redirect("/matrix/login", 303)
  end

  store_session(base_url, answer)

  redirect("/matrix/login/setup", 303)
end
