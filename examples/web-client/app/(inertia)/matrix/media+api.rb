# frozen_string_literal: true

# /matrix/media?mxc=mxc://server/id — Matrix media, proxied. `&w=&h=` asks for a thumbnail.
#
# Fractal: utils/media/, which hands matrix-sdk's cache to a GdkPaintable.
#
# WHY A PROXY AND NOT THE mxc:// STRAIGHT IN AN <img>. Two reasons, either alone enough. A browser
# has no mxc:// scheme, so it does not even try: ERR_UNKNOWN_URL_SCHEME. And since MSC3916 the
# homeserver's media endpoints require authentication, so the real URL cannot go in an <img src>
# either -- the device's access token is not something to hand the page. The bytes have to come
# through something holding the credential, which is this.
#
# NO __END__ AND NO PAGE, which is what the +api suffix says: this answers with bytes.
#
# STREAMED, NEVER BUFFERED. Content.get builds a representation by reading the whole body, so it is
# asked for with a block instead, which yields the response while the body is still arriving. The
# chunks go straight out, so a 40MB video costs a chunk of memory rather than 40MB of it. Falcon
# runs this in a fiber, so the read yields the reactor rather than holding a thread.
#
# DELIBERATELY NARROW. The only thing a caller can ask for is an mxc this device can already see;
# the server name and media id are parsed out and re-encoded by the library, and anything which is
# not a well formed mxc is a 400 before a request is made.
MXC = %r{\Amxc://(?<server>[^/]+)/(?<id>[A-Za-z0-9_-]+)\z}

get "/" do
  match = MXC.match(params["mxc"].to_s)

  if match.nil?
    halt(400, "matrix: not an mxc:// uri\n")
  end

  credential = Models::Matrix::Credential.first

  unless credential&.usable?
    halt(503, "matrix: no credential\n")
  end

  width = params["w"].to_i
  height = params["h"].to_i

  client = Matrix::Session.client(credential)
  repo = client.authed_content_repo

  # The thumbnail endpoint when asked for a size, download otherwise. `scale` keeps the whole image
  # in frame, which is what an avatar wants; `crop` would cut heads off.
  begin
    if width.positive? && height.positive?
      response = repo.get_content_thumbnail_authed(
        match[:server], match[:id], width, height, method: "scale",
      ){|_resource, answer, _klass| answer}
    else
      response = repo.get_content_authed(match[:server], match[:id]){|_resource, answer, _klass| answer}
    end
  rescue Async::Matrix::RequestError => error
    client.close

    halt(error.status || 502, "matrix media: #{error.message}\n")
  end

  unless response.success?
    status = response.status
    response.close
    client.close

    halt(status, "matrix media: the homeserver refused\n")
  end

  content_type(response.headers["content-type"] || "application/octet-stream")

  headers(
    # An mxc id names exactly one blob forever, so the browser never has to ask twice.
    "cache-control"     => "private, max-age=31536000, immutable",
    # Nothing may sit on this response accumulating it -- nginx buffers proxied responses by
    # default and would hold the whole file.
    "x-accel-buffering" => "no",
  )

  stream do |out|
    body = response.body

    begin
      body&.each{|chunk| out << chunk}
    ensure
      body&.close
      client.close
    end
  end
end
