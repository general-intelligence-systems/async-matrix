# frozen_string_literal: true

# /matrix/callback — where the homeserver sends the browser back.
#
# NO __END__ AND NO PAGE. This only ever redirects, so it is a route without a component; the Vite
# plugin keys pages off the __END__ block, so leaving it out is what keeps this out of the page map.
#

# Where the SSO redirect lands. Fractal runs a loopback HTTP server for this and closes it once the
# token arrives (login/local_server.rs); a web client already has a URL the homeserver can reach, so
# this route is that server.
#
# The homeserver hands back a one-shot `loginToken`, which is traded for a real session through
# POST /login with m.login.token. There is no client id, no secret and no PKCE verifier to keep,
# because this is the Client-Server SSO flow and not an OAuth client.
get "/" do
  base_url = session[:matrix_base_url].to_s

  if base_url.empty?
    session[:matrix_login_error] = "the sign-in attempt expired; start it again"
    redirect("/matrix/login", 303)
  end

  token = params["loginToken"].to_s

  if token.empty?
    session[:matrix_login_error] = "the homeserver did not return a login token"
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
