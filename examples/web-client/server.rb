# frozen_string_literal: true

require "base64"
require "ratalada"
require "ratalada/sinatra"
require "ratalada/contrib/vite"
require "ratalada/contrib/inertia"

# DB, the matrix_* tables and every model under Models::Matrix, in that order.
# One database per session, named by MATRIX_SESSION; the tables are created on
# every boot and the creates are idempotent.
require_relative "config/sequel"

RELOAD = "USR2"
reloading = false

Signal.trap(RELOAD) do
  reloading = true
  Process.kill("INT", Process.pid)
end

Server
  .use(Ratalada::Contrib::Inertia::JsonParamsMiddleware)
  .use(Ratalada::Contrib::Vite::DevServerProxy)
  .use(Ratalada::Contrib::Inertia::Middleware)
  .use(WebOnlyCSRF)
  .use(SyncAuth)
  .run do
    extend Ratalada::Contrib::Inertia

    Ratalada::Contrib::Router::FileBased
      .mount(self, File.expand_path("app", __dir__))
  end
