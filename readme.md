# Async::Matrix

A client for the [Matrix](https://matrix.org) client-server API, built on
[async-rest](https://github.com/socketry/async-rest).

The scope is rooms and sync: logging in, enumerating and creating rooms, reading room state and
members, sending events, paging through a timeline, and running a sync loop.

## Usage

``` ruby
require "async/matrix"

Async::Matrix::Client.open("http://localhost:8008") do |unauthenticated|
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
