# frozen_string_literal: true

require "base64"
require "sequel"

Sequel.extension :fiber_concurrency

# SQLite through extralite, which vendors its own (3.44+, so the matrix_*
# tables' JSONB columns work whatever the system library is). The adapter ships
# with the gem rather than with Sequel; requiring it is what registers the
# scheme.
#
# Migrations.create! is idempotent, so it runs on every boot: it creates what is
# missing and leaves what is there, and on a database imported from the Rails
# app it adds the columns that app never had.
#DB = Sequel.connect(ENV.fetch("DATABASE_URL", "extralite://matrix.db"))
#Models::Matrix::Migrations.create!(DB)

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
