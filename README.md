# Async::Matrix

A client for the [Matrix](https://matrix.org) client-server API, built on
[async-rest](https://github.com/socketry/async-rest).

The scope is rooms and sync: logging in, enumerating and creating rooms, reading room state and
members, sending events, paging through a timeline, and running a sync loop.

## Usage

``` ruby
require "async/matrix"

Async::Matrix::Client.open("http://localhost:7300") do |unauthenticated|
	client = unauthenticated.logged_in("alice", "password")
	
	room = client.create_room(name: "Hello", topic: "Built with async-rest")
	room.send_message("Hello, World!")
	
	client.get_joined_rooms.each do |room|
		puts "#{room.id}: #{room.state.name}"
	end
	
	# Sync is a long poll: each batch continues from the one before it.
	sync = client.sync(timeout: 0)
	
	while true
		sync = sync.following(timeout: 30_000)
		
		sync.each_message do |room_id, sender, body, event|
			puts "#{room_id} #{sender}: #{body}"
		end
	end
end
```

See `examples/echo.rb` for a bot which joins rooms it is invited to and replies to every message.

## Design

The library follows the `async-rest` model: a {Async::Matrix::Client} is a *resource*, and every
response is a *representation*.

  - **Paths are absolute.** The client-server API is versioned per-endpoint (`/_matrix/client/v3`
    for most endpoints, `/_matrix/client/v1` for some), so the client is rooted at the homeserver
    and each method supplies an absolute path, which replaces rather than extends the resource path.

  - **Errors are raised by the wrapper.** Matrix reports failures with a non-2xx status and an
    `{errcode, error}` body. `async-rest`'s generated class methods do not check the status, so
    {Async::Matrix::Wrapper} inspects it and raises {Async::Matrix::RequestError}.

  - **Rate limiting is retried.** Matrix reports `M_LIMIT_EXCEEDED` with `retry_after_ms` in the
    *body*, where `async-rest` only understands the `retry-after` header. The wrapper handles both,
    and surfaces the error rather than waiting when the delay exceeds
    `Wrapper::MAXIMUM_RETRY_DELAY`.

  - **A room is a resource with no representation.** There is no `GET /rooms/{roomId}`, so
    {Async::Matrix::Room} is a navigator onto a room's state, members and timeline, carrying the
    room ID alongside its resource.

  - **Representations are lazy.** `client.get_joined_rooms` issues no request until something reads its
    value, and a room enumerated from a collection carries its ID without a further request.

## The server-server API

{Async::Matrix::ServerServer::Server} is the federation client: a resource rooted at another
homeserver, with a navigator per concept the specification names and a representation per answer.

``` ruby
require "async/matrix"

key = Async::Matrix::ServerKey.load("/etc/synapse/signing.key")

Async::Matrix::ServerServer::Server.open("https://matrix.example.com") do |unsigned|
	server = unsigned.signed_as("example.com", key, "matrix.example.com")
	
	puts unsigned.server_version.get_version.name
	puts server.query.query_profile("@alice:matrix.example.com").displayname
	
	# A join is a template to sign and send back:
	template = server.joins_v1.make_join(room_id, "@bob:example.com", versions: ["11"])
end
```

  - **There is no access token.** A server proves who it is by signing the request, so
    {Async::Matrix::Middleware::Signed} sits below the resource and signs the method, the path, the
    origin, the destination and the body as a document. The signature is over the canonical form
    rather than over the bytes, so it cannot depend on how the sender wrote them.

  - **The signing key is the server's own.** {Async::Matrix::ServerKey} reads the one line a
    homeserver keeps its ed25519 key in, and is what the other side fetches from
    `/_matrix/key/v2/server` to check a signature against.

  - **Some endpoints are not signed at all.** The version, the keys, the discovery document and the
    OpenID exchange are read before there is anything to sign with, so they are asked for through
    the unsigned resource.

  - **Media comes back in two parts.** `/media/download` answers `multipart/mixed`: a document
    describing the file, and then the file, or a `Location` pointing at it.
    {Async::Matrix::Wrapper::Multipart} reads both, so {Async::Matrix::ServerServer::FederatedContent}
    has bytes and a description rather than a body to parse.

  - **An event carries no ID.** Since room version 3 an event ID is the hash of its redacted form
    rather than a field, so a representation reads events by type rather than looking one up by ID.

  - **Two endpoints were withdrawn.** v1.18 dropped the first versions of `send_join` and
    `send_leave`, so those layers register the withdrawal and the methods say what replaced them.

The suite signs as the homeserver it is testing, using the key checked into `synapse/`: a
homeserver verifies a signature made by its own server name against the key it already holds rather
than fetching one, so every authenticated endpoint is reachable from a single server. There is no
other way to do it - a server name invented by the suite would have no keys for anybody to fetch.

## End-to-end encryption

Encryption is two ratchets, not one. **Olm** is a channel between a pair of devices, and it carries
the keys. **Megolm** is a session for a room, and it carries the messages. So every key a client
needs arrives inside an Olm-encrypted to-device message, and every message arrives inside a Megolm
one - an `m.room_key` is never seen as an `m.room_key` on the wire, but as an `m.room.encrypted`
which decrypts into one.

{Async::Matrix::E2EE::Machine} holds key material and session state, and nothing else. It has no
resource, it makes no request, and it is told whatever it cannot work out for itself. Every request
here is the client's, through the same navigators as the rest of the library:
{Async::Matrix::ClientServer::Keys} for the key management API, and
{Async::Matrix::ClientServer::ToDevice} for delivery. What the machine contributes is the
cryptography and the bookkeeping - which session a room is on, which private keys are still unpublished,
and which events are waiting for a key that has not arrived.

Publishing a device is therefore two steps which do not know about each other: the machine
generates, and the client uploads what it generated.

``` ruby
require "async/matrix"

require "console"

Async::Matrix::ClientServer::Client[Async::Matrix::LATEST].open(HOMESERVER) do |unauthenticated|
	client = unauthenticated.logged_in(USER, PASSWORD)
	
	# The machine is told who it is, because finding out is a request and it makes none.
	owner = client.get_token_owner
	
	machine = Async::Matrix::E2EE::Machine.new(
		user_id: owner.user_id,
		device_id: owner.device_id,
		crypto: Async::Matrix::E2EE::Plaintext.new,
	)
	
	# The keys other devices will open an Olm session with.
	machine.crypto.generate_one_time_keys(machine.crypto.one_time_key_target)
	
	uploaded = client.keys.upload_keys(
		device_keys: machine.device_keys,
		one_time_keys: machine.signed_one_time_keys,
	)
	
	# Forget the private halves which are now published, so none is ever offered twice.
	machine.crypto.published_one_time_keys!
	
	Console.info(self, "Published keys.", counts: uploaded.one_time_key_counts)
end
```

Sharing a session is four requests and no cleverness: who is in the room, what keys they have, a one
time key for each device there is no Olm session with yet, and then the session itself.

``` ruby
# Share the room's current Megolm session with every device which should hold it.
share = lambda do |room_id, rotate: false|
	user_ids = client.room(room_id).get_joined_members_by_room.user_ids
	queried = client.keys.query_keys(user_ids.to_h{|user_id| [user_id, []]})
	
	# Only cross signed devices are given the session. The rest are told why they were not, which is what lets them explain themselves to their user.
	recipients, refused = machine.recipients(queried).partition(&:cross_signed?)
	
	# A device we have never spoken to needs a one time key before it can be addressed at all.
	wanted = machine.without_sessions(recipients)
	
	unless wanted.empty?
		machine.accept_claimed_keys(client.keys.claim_keys(wanted))
	end
	
	session = machine.session_for(room_id, rotate: rotate)
	
	room_key = {
		algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
		room_id: room_id,
		session_id: session[:session_id],
		session_key: session[:session_key],
		# Says the session may be passed on to members who join later, which is true only while the room's history is visible to them.
		shared_history: machine.shared_history?(room_id),
	}
	
	# The key travels Olm encrypted, so what is sent is an `m.room.encrypted` rather than an `m.room_key`.
	messages = recipients.group_by(&:user_id).transform_values do |devices|
		devices.to_h{|device| [device.device_id, machine.encrypt_to_device(device, "m.room_key", room_key)]}
	end
	
	client.to_device.send_to_device("m.room.encrypted", messages)
	
	unless refused.empty?
		withheld = refused.group_by(&:user_id).transform_values do |devices|
			devices.to_h do |device|
				[device.device_id, {
					algorithm: Async::Matrix::E2EE::Machine::MEGOLM,
					room_id: room_id,
					session_id: session[:session_id],
					sender_key: machine.crypto.identity_keys[:curve25519],
					code: "m.unverified",
					reason: "This device is not cross signed.",
				}]
			end
		end
		
		# A withheld report is sent in the clear, since the point of it is that there is no session to send it over.
		client.to_device.send_to_device("m.room_key.withheld", withheld)
	end
end
```

And then the loop, which is where the events become a `case`. This is the point of the dedicated
event types: an encrypted message, a message sent in the clear, a key which has not arrived yet and
a key which never will are four patterns, not four error codes.

``` ruby
me = owner.user_id

# Which rooms a session has already been shared with, since a session is shared once rather than per message.
shared = Set.new

# The initial sync reports all current state, which is skipped: the first batch is used for its cursor alone.
sync = client.sync(timeout: 0)

sync.each(retries: 3) do |batch|
	# The batch says how many one time keys the server still holds. The machine decides whether that is too few; the client does the uploading.
	if machine.one_time_keys_low?(batch.one_time_keys_count)
		machine.crypto.generate_one_time_keys(machine.crypto.one_time_key_target)
		client.keys.upload_keys(one_time_keys: machine.signed_one_time_keys)
		machine.crypto.published_one_time_keys!
	end
	
	# Whoever changed their devices or cross signing keys must be looked up again before anything is encrypted to them.
	unless batch.changed_devices.empty?
		machine.accept_queried_keys(client.keys.query_keys(batch.changed_devices.to_h{|user_id| [user_id, []]}))
	end
	
	machine.forget(batch.left_devices)
	
	# Every event this device can read. To-device messages are handled first, so a key which arrives in this batch releases the messages which were waiting for it, including ones from earlier batches.
	machine.each_event(batch) do |event|
		case event
		# Our own message, which comes back in sync like anybody else's.
		in {sender: ^me, content: Async::Matrix::Events::Message}
			# Don't reply to ourselves, or we will talk forever.
		
		# A message we could read. `session_id` is carried only by an event which arrived encrypted, so this arm says "encrypted" without having to ask, and must come before the cleartext one.
		in {room_id:, sender:, session_id:, content: Async::Matrix::Events::TextMessage(body:)}
			unless shared.include?(room_id)
				share.call(room_id)
				shared.add(room_id)
			end
			
			reply = Async::Matrix::Events::TextMessage.build(body: "You said: #{body}")
			content = machine.encrypt(room_id, reply)
			
			client.room(room_id).send_message(content.type, content.to_h)
		
		# The same message, sent in the clear into a room we are encrypting.
		in {sender:, content: Async::Matrix::Events::TextMessage(body:)}
			Console.warn(self, "A message arrived unencrypted.", sender: sender, body: body)
		
		# The key has not arrived. The event is kept, and comes back through this loop when it does.
		in {content: Async::Matrix::Events::Deferred(session_id:)}
			Console.info(self, "Waiting for a session.", session_id: session_id)
		
		# A device deliberately did not share, and said why. `m.unverified` resolves when it is verified; the others do not.
		in {sender:, content: Async::Matrix::Events::Withheld(code: "m.unverified")}
			Console.warn(self, "A device will not share until it is verified.", sender: sender)
		
		# No Olm session could be established, so this one report explains every message that device sent before it. The answer is a session of our own, and an `m.dummy` over it to say so.
		in {sender:, content: Async::Matrix::Events::Withheld(code: "m.no_olm")}
			device = machine.device_of(sender, event.content[:sender_key])
			
			machine.accept_claimed_keys(client.keys.claim_keys(machine.without_sessions([device])))
			client.to_device.send_to_device("m.room.encrypted", {
				sender => {device.device_id => machine.encrypt_to_device(device, "m.dummy", {})},
			})
		
		in {sender:, content: Async::Matrix::Events::Withheld(code:, reason:)}
			Console.warn(self, "A session was withheld.", sender: sender, code: code, reason: reason)
		
		# The key arrived and the message still did not read, which is a fault rather than a wait.
		in {content: Async::Matrix::Events::Undecryptable(session_id:)}
			Console.error(self, "Could not read an event.", session_id: session_id)
		
		# The room turned encrypted, so a session is wanted before anything is sent into it.
		in {room_id:, content: Async::Matrix::Events::RoomEncryption(algorithm:)}
			share.call(room_id)
			shared.add(room_id)
		
		# Somebody left, so the session they hold must not encrypt anything further. Since v1.19 an invited user counts too, because history sharing may have given them the keys.
		in {room_id:, content: Async::Matrix::Events::RoomMember(membership: "leave" | "ban")}
			share.call(room_id, rotate: true)
		
		# Invited to a room, so join it. The keys for its history may already be waiting in a bundle.
		in {room_id:, state_key: ^me, content: Async::Matrix::Events::RoomMember(membership: "invite")}
			client.join_room(room_id)
		
		# Another of our own devices is missing a session we hold, and only this user's verified devices are answered.
		in {sender: ^me, content: Async::Matrix::Events::RoomKeyRequest(action: "request")}
			if forwarded = machine.forwardable(event)
				client.to_device.send_to_device("m.room.encrypted", forwarded)
			end
		
		in {content: Async::Matrix::Events::RoomKeyRequest(action: "request_cancellation", request_id:)}
			Console.debug(self, "A key request was cancelled.", request_id: request_id)
		
		# A session arrived, which the machine has accepted and used to release whatever was waiting. Those released events come through this same loop.
		in {sender:, content: Async::Matrix::Events::RoomKey(room_id:, session_id:)}
			Console.debug(self, "Accepted a session.", sender: sender, room_id: room_id, session_id: session_id)
		
		in {sender:, content: Async::Matrix::Events::ForwardedRoomKey(forwarding_curve25519_key_chain:)}
			Console.debug(self, "Accepted a forwarded session.", sender: sender, hops: forwarding_curve25519_key_chain.size)
		
		# A bundle of history for a room we were invited to. It is a file to fetch, which is done on accepting the invite rather than now, so that nobody can make us download what we never asked for.
		in {sender:, content: Async::Matrix::Events::RoomKeyBundle(room_id:)}
			Console.info(self, "Keys for a room's history are waiting.", sender: sender, room_id: room_id)
		
		# A device announced a replacement Olm session, having found the old one corrupt.
		in {sender:, content: Async::Matrix::Events::Dummy}
			Console.debug(self, "A device replaced its session.", sender: sender)
		
		# One of our own devices asked for a secret: a cross signing key, or the backup decryption key.
		in {sender: ^me, content: Async::Matrix::Events::SecretRequest(action: "request", name:)}
			Console.info(self, "A device asked for a secret.", name: name)
		
		in {sender: ^me, content: Async::Matrix::Events::SecretSend(request_id:)}
			Console.info(self, "A secret arrived.", request_id: request_id)
		
		# A verification is a handshake, and it is driven the same way as everything else here: the machine does the cryptography, the client sends the result.
		in {sender:, content: Async::Matrix::Events::KeyVerificationRequest(from_device:, transaction_id:, methods:)} if methods.include?("m.sas.v1")
			ready = {methods: ["m.sas.v1"], from_device: machine.device_id, transaction_id: transaction_id}
			
			client.to_device.send_to_device("m.key.verification.ready", {sender => {from_device => ready}})
		
		# The other side chose SAS, so the accept narrows their offer to what we will use: decimal, since MSC4405 deprecated emoji.
		in {sender:, content: Async::Matrix::Events::KeyVerificationStartSasV1(from_device:, transaction_id:) => start}
			sas = Async::Matrix::E2EE::Sas.new
			
			accept = {
				transaction_id: transaction_id,
				key_agreement_protocol: "curve25519-hkdf-sha256",
				hash: "sha256",
				message_authentication_code: "hkdf-hmac-sha256.v2",
				short_authentication_string: start.agreed,
				commitment: machine.commitment(sas, start),
			}
			
			client.to_device.send_to_device("m.key.verification.accept", {sender => {from_device => accept}})
		
		in {sender:, content: Async::Matrix::Events::KeyVerificationCancel(code:)}
			Console.warn(self, "A verification was cancelled.", sender: sender, code: code)
		
		in {sender:, content: Async::Matrix::Events::KeyVerificationDone}
			Console.info(self, "A device is now verified.", sender: sender)
		
		else
			Console.debug(self, "Ignoring an event we do not handle.", type: event.type)
		end
	end
end
```

What the loop is doing, and why it is shaped this way:

  - **The machine makes no requests.** It is handed the batch, the queried keys and the claimed
    keys, and it answers with content to send and events to read. That is what keeps it testable
    without a homeserver, and it is why `one_time_keys_low?` is given the count from the batch
    rather than fetching one.

  - **To-device messages come first.** A key which arrives in a batch can unlock a message which
    arrives in the same batch, so the machine drains `to_device` before the timeline. This is also
    why the machine owns the stream rather than {Async::Matrix::ClientServer::Sync}: the batch is a
    representation, and knows nothing about encryption.

  - **Decryption is not one-to-one.** One ciphertext yields no event when its key has not arrived,
    and one key yields every event which was waiting for it. So a released event is *older* than
    the batch which carried its key: a client ordering by arrival will put history out of order,
    and should order by `origin_server_ts`, which every envelope carries.

  - **Failure is an event, not an exception.** `Deferred`, `Withheld` and `Undecryptable` are
    content classes, so "waiting", "refused" and "broken" are arms of the same `case` rather than a
    `nil` to check. `m.no_olm` is the awkward one: it names no room and no session, and
    retroactively explains everything that device sent.

  - **Rotation is driven by what the loop sees.** A session must be replaced when its time or
    message count runs out, when anyone leaves, and - since v1.19 - when the room's history
    visibility changes in a way that flips `shared_history`. Membership is in the timeline, which
    is why the rotation arm sits here.

  - **Patterns are ordered most specific first.** An encrypted event's `deconstruct_keys` is a
    superset of a cleartext one's, so the arm matching on `session_id:` has to precede the one
    without it, exactly as `TextMessage` precedes `Message`.

The specification this follows is vendored under `lib/async/matrix/e2ee/schema`, prose and event
schemas together, so the flow can be read beside the code: start with
`content/client-server-api/modules/end_to_end_encryption.md`, and `content/olm-megolm/` for the two
ratchets themselves.

{Async::Matrix::E2EE::Plaintext} is the only {Async::Matrix::E2EE::Crypto} the library ships. It
reverses rather than encrypts, and says so in every message it writes, so that this loop can be
driven end to end before a binding exists. `ext/async_matrix_e2ee` is the Rust crate
([magnus](https://github.com/matsadler/magnus) over
[vodozemac](https://github.com/matrix-org/vodozemac)) a real one will be built on.

## Documentation

`docs/` is a documentation site built with [Fumadocs](https://fumadocs.dev), which the
Documentation workflow publishes to GitHub Pages as a static export. It is a Node project of its
own, and the gem does not depend on it:

``` shell
cd docs
npm install
npm run dev     # http://localhost:3000
```

Its pages are MDX in `docs/content/docs`, written there rather than generated from this file and
`guides/`, so a change to either has to be made in both places. See `docs/README.md`.

## Testing

The tests run against a real homeserver, and against more than one of them. There is a rig per
backend, each a directory with a flake which publishes one image per Matrix specification version
and a compose file with a service per version, so that a run is just the version wanted:

``` shell
bin/test                      # the latest version, on Synapse
bin/test --all                # every version
bin/test v1.11 v1.12          # just these
bin/test --backend tuwunel    # on tuwunel instead
bin/test --keep-alive         # and leave the homeserver running afterwards
```

`synapse/` is the first rig, and pins each specification version to the Synapse which first
advertised it, which is the oldest server that version can be tested against. `tuwunel/` is the
second, and pins every version to the same tuwunel release: one tuwunel build advertises the whole
range, and its advertised list records the order it did the work in rather than when support
arrived, so the first release to advertise v1.5 predates most of its development.

A second backend is the point rather than a bonus. A suite which only ever talks to Synapse tests
what Synapse does, not what the specification says, so where a version passes on one server and
fails on the other, either one of them is wrong or the specification is read two ways.

Each test gets a fresh user and a fresh room, so tests cannot interfere with each other and the
suite can be run repeatedly. The one thing the rigs cannot do alike is make that user: Synapse
carries a module which registers it on first login, where tuwunel has no way to accept any
password, so its rig opens registration and the suite registers the account before logging in.
`bin/test` tells the suite which it is talking to.

Set `MATRIX_HOMESERVER` to test against a server of your own — but note that one with default rate
limits will fail the suite, because Synapse allows a burst of 10 room creations and then one per
~62 seconds, and a burst of 5 logins and then one per ~5 minutes.

The images come from the Build Test Images workflows, which is also what a new version needs run
after it is added: a job pulls `ghcr.io/<owner>/<backend>:spec-<version>`, so without it there is
nothing to start.

### Linting

``` shell
bin/rubocop
```

The cops in `cops/` read files with Prism through `ast-crispr-ruby-prism`, which requires Ruby 4,
so they are in a `lint` bundler group of their own. The suite itself runs on Ruby 3.3 and up, and
the Test workflows install without that group.
