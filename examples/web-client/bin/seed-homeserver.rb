# frozen_string_literal: true

require "async/matrix"

require_relative "../lib/matrix/homeserver"

BASE_URL = ENV.fetch("MATRIX_HOMESERVER_URL", "http://localhost:8008")

USER = ENV.fetch("MATRIX_USER", "alice")

PASSWORD = ENV.fetch("MATRIX_PASSWORD", "password")

ROOMS = [
  {name: "General", topic: "Everything and nothing"},
  {name: "Design", topic: "Pixels, mostly"},
  {name: "Incidents", topic: "When it breaks"},
].freeze

def register_or_login(client)
  client.registration.register(username: USER, password: PASSWORD)
rescue Async::Matrix::InteractiveAuthenticationError => challenge
  stages = challenge.flows.flat_map{|flow| flow[:stages] || flow["stages"] || []}

  unless stages.include?("m.login.dummy")
    raise
  end

  client.registration.register(
    username: USER,
    password: PASSWORD,
    auth: {type: "m.login.dummy", session: challenge.session},
  )
rescue Async::Matrix::RequestError => error
  unless error.errcode == "M_USER_IN_USE"
    raise
  end

  warn("seed: #{USER} exists, logging in instead")

  client.login(USER, PASSWORD)
end

Sync do
  client = Async::Matrix::ClientServer::Client[Matrix::Homeserver::VERSION].open(BASE_URL)

  begin
    session = register_or_login(client)

    warn("seed: #{session.user_id} on #{session.device_id}")

    authenticated = client.authenticated(session.access_token)

    existing = authenticated.get_joined_rooms.ids.size

    ROOMS.each do |room|
      created = authenticated.create_room(name: room[:name], topic: room[:topic])

      message = Async::Matrix::Events::TextMessage.build(body: "Welcome to #{room[:name]}.")

      created.send_message(message.type, message.to_h)

      warn("seed: created #{room[:name]} (#{created.id})")
    end

    warn("seed: #{authenticated.get_joined_rooms.ids.size} rooms joined (#{existing} before)")
    warn("seed: log in at http://localhost:9292 as #{USER} / #{PASSWORD}")
  ensure
    client.close
  end
end
