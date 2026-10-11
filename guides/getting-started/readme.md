# Getting Started

This guide explains how to use the `async-matrix` gem to talk to a Matrix homeserver.

## Installation

Add the gem to your project:

``` shell
$ bundle add async-matrix
```

## Core Concepts

- A {ruby Async::Matrix::Client} is an `Async::REST::Resource` rooted at a homeserver. An
  unauthenticated client can read `/versions` and log in; {ruby Async::Matrix::Client#authenticated}
  derives a client which carries an access token.
- A {ruby Async::Matrix::Room} is a navigator onto one room. It is not a representation, because the
  client-server API has no `GET /rooms/{roomId}`: a room is only ever observed through its state,
  members or timeline.
- Everything a request returns is a {ruby Async::Matrix::Representation}: {ruby Async::Matrix::State},
  {ruby Async::Matrix::Messages}, {ruby Async::Matrix::Sync} and so on.

## Logging In

``` ruby
require "async/matrix"

Async::Matrix::Client.open("http://localhost:8008") do |unauthenticated|
	client = unauthenticated.logged_in("alice", "password")
	
	puts client.get_token_owner.user_id
	# @alice:localhost
end
```

If you already hold an access token, skip the login:

``` ruby
client = unauthenticated.authenticated(ENV["MATRIX_ACCESS_TOKEN"])
```

## Rooms

``` ruby
room = client.create_room(name: "Planning", topic: "Sprint planning")

room.send_message("Hello, World!")

puts room.state.name
# Planning
puts room.joined_members.user_ids
# ["@alice:localhost"]
```

Nothing is fetched until it is read, so listing rooms is cheap, and each room enumerated from the
list already knows its own ID:

``` ruby
client.get_joined_rooms.each do |room|
	puts room.id
end
```

A timeline is paged with opaque tokens. {ruby Async::Matrix::Messages#following} continues from
where the previous page ended, and returns `nil` at the end:

``` ruby
page = room.get_room_events(dir: "b", limit: 20)

while page
	page.each do |event|
		puts event.dig(:content, :body)
	end
	
	page = page.following
end
```

## Sync

`/sync` is a long poll: the server holds the request open until something happens, or until the
timeout expires. Each batch carries the token the next one should continue from, so a sync loop is a
chain of {ruby Async::Matrix::Sync#following} calls.

``` ruby
# The initial sync reports all current state. Use `timeout: 0` for it, and treat it as a cursor:
sync = client.sync(timeout: 0)

while true
	sync = sync.following(timeout: 30_000)
	
	sync.each_message do |room_id, sender, body, event|
		puts "#{room_id} #{sender}: #{body}"
	end
end
```

Note that the room IDs in a parsed payload are symbols, because the JSON parser symbolizes names.
{ruby Async::Matrix::Sync#each_event} and {ruby Async::Matrix::Sync#each_message} convert them back
to strings for you; {ruby Async::Matrix::Sync#joined} does not.

## Errors and Rate Limiting

A failed request raises {ruby Async::Matrix::RequestError}, which carries the HTTP status and the
Matrix `errcode`:

``` ruby
begin
	client.join("#nonexistent:localhost")
rescue Async::Matrix::RequestError => error
	puts error.status  # 404
	puts error.errcode # M_NOT_FOUND
end
```

A rate limited request is retried automatically, for as long as the server asks for a delay within
`Async::Matrix::Wrapper::MAXIMUM_RETRY_DELAY`. A longer delay is raised as an error instead, so that
a task is never silently blocked for minutes: Synapse answers a login burst with a penalty of around
five minutes, and you almost certainly want to know rather than wait.
