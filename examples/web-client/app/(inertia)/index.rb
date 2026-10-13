# frozen_string_literal: true

# / — the root, which a Matrix client has nothing of its own to put at.
#
# Fractal opens on its session, and so does this: /matrix is the shell, and
# every room, setting and verification flow hangs off it.
get "/" do
  redirect("/matrix")
end
