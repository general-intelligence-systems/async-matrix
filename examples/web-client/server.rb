# frozen_string_literal: true

require "base64"
require "multi_json"
require "ratalada"
require "ratalada/async"
require "ratalada/sinatra"
require "ratalada/contrib/vite"
require "ratalada/contrib/inertia"
require "ratalada/contrib/router/file_based/sinatra_adapter"

require_relative "config/sequel"
require_relative "lib/matrix/homeserver"

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
  .use(Ratalada::Contrib::Inertia::CSRFMiddleware)
  .run do
    extend Ratalada::Contrib::Inertia

    Ratalada::Contrib::Router::FileBased
      .mount(self, File.expand_path("app", __dir__))
  end
