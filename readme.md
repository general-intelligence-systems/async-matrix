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
	
	client.joined_rooms.each do |room|
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

  - **Representations are lazy.** `client.joined_rooms` issues no request until something reads its
    value, and a room enumerated from a collection carries its ID without a further request.

## Testing

The tests run against a real homeserver. The `examples/matrix` rig in the `async-rest` checkout
alongside this one provides a throwaway Synapse, with every rate limiter disabled and a module which
registers a user on first login, so the suite needs no setup and no fixtures of its own:

``` shell
cd ../async-rest/examples/matrix && docker compose up -d --wait synapse
```

Then:

``` shell
nix develop --command bin/test
```

Each test gets a fresh user and a fresh room, so tests cannot interfere with each other and the
suite can be run repeatedly. Set `MATRIX_HOMESERVER` to test against a different server — but note
that a homeserver with default rate limits will fail the suite, because Synapse allows a burst of 10
room creations and then one per ~62 seconds, and a burst of 5 logins and then one per ~5 minutes.
