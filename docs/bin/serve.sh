#!/usr/bin/env bash
# Serve the docs locally with live reload.
#   docs/bin/serve.sh   |   PORT=4002 docs/bin/serve.sh
set -euo pipefail

# Drop any parent bundle's env so the docs Gemfile resolves on its own.
unset RUBYOPT RUBYLIB BUNDLE_GEMFILE BUNDLE_BIN_PATH BUNDLE_BIN BUNDLE_APP_CONFIG 2>/dev/null || true

PORT="${PORT:-4000}"
docs="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "$docs"
BUNDLE_GEMFILE="$docs/Gemfile" bundle install --quiet
echo "==> Serving http://localhost:$PORT/async-matrix/ — Ctrl-C to stop"
BUNDLE_GEMFILE="$docs/Gemfile" bundle exec jekyll serve --livereload --port "$PORT"
