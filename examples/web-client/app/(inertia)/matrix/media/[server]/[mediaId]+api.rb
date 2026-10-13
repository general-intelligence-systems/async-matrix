# frozen_string_literal: true

# /matrix/media/:server/:mediaId — the bytes behind an mxc:// URI
#
# Fractal: utils/media/, which hands matrix-sdk's media cache to a GdkPaintable.
#
# NO __END__ AND NO PAGE, which is what the +api suffix says: this answers with bytes.
#
# A browser cannot fetch an mxc:// URI, and the authenticated media endpoint wants the access
# token, which does not belong in an <img src>. So the app is the proxy: it serves from
# matrix_media when the file is there and fetches it once when it is not.
get "/" do
  uri = "mxc://#{params["server"]}/#{params["mediaId"]}"

  bytes = Matrix::RoomActions.download(uri)

  if bytes.nil?
    halt(404, "matrix: no such media\n")
  end

  cache_control(:private, max_age: 86_400)

  content_type(Models::Matrix::Event.first(Sequel.like(:content, "%#{params["mediaId"]}%"))
    &.content&.dig("info", "mimetype") || "application/octet-stream")

  bytes
end
