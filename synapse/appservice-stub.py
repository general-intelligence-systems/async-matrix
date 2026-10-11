"""An application service, in as little as answers the specification.

The application service API is served by a bridge: the homeserver calls it, and it answers for the
users and rooms it owns. The rig runs no bridge - every one of them is a bridge to something - so
this answers in its place, which is enough to exercise the operations: each is a request whose shape
the suite is checking, and whose answer it reads.

It owns the user `@stub-user:localhost`, the alias `#stub-room:localhost`, and one protocol, `stub`.
Anything else it does not know, which is the other half of the specification: a service says what it
does not own by answering 404.
"""

import json
import re
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs, unquote

OWNED_USER = "@stub-user:localhost"
OWNED_ALIAS = "#stub-room:localhost"
PROTOCOL = "stub"

PROTOCOLS = {
    PROTOCOL: {
        "user_fields": ["nick"],
        "location_fields": ["channel"],
        "icon": "mxc://localhost/stub",
        "field_types": {
            "nick": {"regexp": ".*", "placeholder": "nick"},
            "channel": {"regexp": ".*", "placeholder": "#channel"},
        },
        "instances": [{"desc": "A stub network", "network_id": "stub", "fields": {}}],
    }
}


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *arguments):
        print("appservice-stub: " + format % arguments, flush=True)

    def answer(self, status, payload):
        body = json.dumps(payload).encode("utf-8")

        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def not_found(self, errcode="M_NOT_FOUND"):
        self.answer(404, {"errcode": errcode, "error": "Not found"})

    def do_GET(self):
        url = urlparse(self.path)
        path = unquote(url.path)
        query = parse_qs(url.query)

        if match := re.fullmatch(r"/_matrix/app/v1/users/(.+)", path):
            return self.answer(200, {}) if match.group(1) == OWNED_USER else self.not_found()

        if match := re.fullmatch(r"/_matrix/app/v1/rooms/(.+)", path):
            return self.answer(200, {}) if match.group(1) == OWNED_ALIAS else self.not_found()

        if path == "/_matrix/app/v1/thirdparty/protocols":
            return self.answer(200, PROTOCOLS)

        if match := re.fullmatch(r"/_matrix/app/v1/thirdparty/protocol/(.+)", path):
            protocol = PROTOCOLS.get(match.group(1))
            return self.answer(200, protocol) if protocol else self.not_found()

        if match := re.fullmatch(r"/_matrix/app/v1/thirdparty/location(?:/(.+))?", path):
            if match.group(1) and match.group(1) != PROTOCOL:
                return self.not_found()

            if match.group(1) or query.get("alias") == [OWNED_ALIAS]:
                return self.answer(200, [{"alias": OWNED_ALIAS, "protocol": PROTOCOL, "fields": {"channel": "#stub"}}])

            return self.answer(200, [])

        if match := re.fullmatch(r"/_matrix/app/v1/thirdparty/user(?:/(.+))?", path):
            if match.group(1) and match.group(1) != PROTOCOL:
                return self.not_found()

            if match.group(1) or query.get("userid") == [OWNED_USER]:
                return self.answer(200, [{"userid": OWNED_USER, "protocol": PROTOCOL, "fields": {"nick": "stub"}}])

            return self.answer(200, [])

        return self.not_found("M_UNRECOGNIZED")

    def read_body(self):
        length = int(self.headers.get("Content-Length", 0))

        return json.loads(self.rfile.read(length) or b"{}")

    def do_PUT(self):
        path = unquote(urlparse(self.path).path)

        if re.fullmatch(r"/_matrix/app/v1/transactions/(.+)", path):
            self.read_body()

            return self.answer(200, {})

        return self.not_found("M_UNRECOGNIZED")

    def do_POST(self):
        path = unquote(urlparse(self.path).path)

        if path == "/_matrix/app/v1/ping":
            self.read_body()

            return self.answer(200, {})

        return self.not_found("M_UNRECOGNIZED")


if __name__ == "__main__":
    ThreadingHTTPServer(("", 8099), Handler).serve_forever()
