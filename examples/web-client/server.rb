# frozen_string_literal: true

require "base64"
require "multi_json"
require "ratalada"
require "ratalada/async"
require "ratalada/sinatra"
require "ratalada/contrib/vite"
require "ratalada/contrib/inertia"
require "ratalada/contrib/router/file_based/sinatra_adapter"

require_relative "config/sequel"
require_relative "lib/matrix/homeserver"
require_relative "lib/matrix/session"
require_relative "lib/matrix/room_actions"
require_relative "lib/matrix/crypto"
require_relative "lib/matrix/verification"

RELOAD = "USR2"
reloading = false

Signal.trap(RELOAD) do
  reloading = true
  Process.kill("INT", Process.pid)
end

Events = Async::Matrix::Events

M = Models::Matrix

SYNC_TIMEOUT = Integer(ENV.fetch("MATRIX_SYNC_TIMEOUT", "30000"))

FAVOURITE = :"m.favourite"

LOW_PRIORITY = :"m.lowpriority"

UNSTABLE_MARKED_UNREAD = "com.famedly.marked_unread"

MEMBER_HINTS = "io.element.functional_members"

RETENTION = "m.room.retention"

CALL_MEMBER = "m.call.member"

def upsert(model, keys)
  model.first(**keys) || model.new(**keys)
end

def store_state(event, stripped)
  M::RoomState.dataset
    .where(room_id: event.room_id, event_type: event.type, state_key: event.state_key.to_s)
    .delete

  M::RoomState.new(
    room_id: event.room_id, event_type: event.type, state_key: event.state_key.to_s,
    stripped: stripped, event_id: event.event_id, sender: event.sender,
    origin_server_ts: event.origin_server_ts, content: event.content.to_h,
    prev_content: event.dig(:unsigned, :prev_content),
  ).save(validate: false)
end

def store_event(event)
  M::Event.dataset.where(event_id: event.event_id).delete

  relates = event.content.to_h[:"m.relates_to"] || {}

  M::Event.new(
    event_id: event.event_id, room_id: event.room_id, sender: event.sender, type: event.type,
    state_key: event.is_a?(Events::StateEvent) ? event.state_key : nil,
    content: event.content.to_h, origin_server_ts: event.origin_server_ts || 0,
    relates_to_id: relates[:event_id], rel_type: relates[:rel_type],
  ).save(validate: false)
end

def touch_latest(room, event)
  room.latest_event = event.to_h
  room.last_activity_at = event.origin_server_ts
end

def apply_state(room, event, stripped, me)
  store_state(event, stripped)

  case event
  in {content: Events::RoomCreate => content}
    unless room.room_version
      room.room_version = content.room_version
      room.creator = content.creator || event.sender
      room.space = content.to_h[:type] == "m.space"
      room.federated = content.to_h.fetch(:"m.federate", true)
      room.predecessor_room_id = content.predecessor && content.predecessor[:room_id]
    end
  in {content: Events::RoomName => content}
    room.name = content.name
  in {content: Events::RoomTopic => content}
    room.topic = content.topic
  in {content: Events::RoomAvatar => content}
    room.avatar_url = content.url
  in {content: Events::RoomCanonicalAlias => content}
    room.canonical_alias = content.alias
    room.alt_aliases = content.alt_aliases || []
  in {content: Events::RoomJoinRules => content}
    room.join_rule = content.join_rule
    room.join_rule_allow = content.to_h[:allow] || []
  in {content: Events::RoomEncryption => content}
    unless content.algorithm.nil?
      room.encrypted = true
      room.encryption = content.to_h
    end
  in {content: Events::RoomTombstone => content}
    room.tombstoned = true
    room.successor_room_id = content.replacement_room
  in {content: Events::RoomPowerLevels => content}
    room.max_power_level = (content.users || {}).values.map(&:to_i).max || 0
  in {content: Events::RoomHistoryVisibility => content}
    room.history_visibility = content.history_visibility
  in {content: Events::RoomGuestAccess => content}
    room.guest_access = content.guest_access
  in {content: Events::RoomPinnedEvents => content}
    room.pinned = content.pinned || []
  in {type: RETENTION, content:}
    room.retention = content.to_h
  in {type: MEMBER_HINTS, content:}
    room.member_hints = content.to_h
  in {type: CALL_MEMBER, state_key:, content:}
    members = room.rtc_members.to_h

    if content.to_h.empty?
      members.delete(state_key.to_s)
    else
      members[state_key.to_s] = content.to_h
    end

    room.rtc_members = members
  in {content: Events::RoomMember => content}
    apply_member(room, event, content, stripped, me)
  else
    nil
  end
end

def apply_member(room, event, content, stripped, me)
  member_id = event.state_key.to_s
  membership = content.membership
  displayname = content.displayname
  avatar_url = content.avatar_url

  unless member_id.empty?
    M::RoomMember.dataset.where(room_id: room.room_id, member_id: member_id).delete

    M::RoomMember.new(
      room_id: room.room_id, member_id: member_id, membership: membership || "leave",
      display_name: displayname, avatar_url: avatar_url, stripped: stripped,
    ).save(validate: false)

    joined = membership == "join" || membership == "invite"

    if membership == "join"
      upsert(M::GlobalProfile, {matrix_user_id: member_id})
        .set(display_name: displayname, avatar_url: avatar_url)
        .save_changes(validate: false)
    end

    unless displayname.to_s.empty?
      row = upsert(M::MemberDisplayName, {room_id: room.room_id, display_name: displayname})
      members = Array(row.member_ids)

      if joined
        row.member_ids = (members + [member_id]).uniq
      else
        row.member_ids = members - [member_id]
      end

      row.save_changes(validate: false)
    end

    if joined
      upsert(M::TrackedUser, {matrix_user_id: member_id}).set(dirty: true).save_changes(validate: false)
    end

    if content.is_direct
      room.direct = true
    end

    if member_id == me
      room.membership = membership || room.membership
    end
  end
end

def apply_timeline(room, event, me)
  if event.is_a?(Events::StateEvent)
    apply_state(room, event, false, me)
  end

  unless event.event_id.to_s.empty?
    store_event(event)
  end

  case event
  in {content: Events::RoomRedaction}
    target = event.content.to_h[:redacts] || event.to_h[:redacts]

    unless target.to_s.empty?
      M::Event.where(event_id: target).update(redacted: true, content: "{}")
    end
  in {content: Events::Message}
    touch_latest(room, event)

    relates = event.content.to_h[:"m.relates_to"] || {}

    if relates[:rel_type] == "m.thread"
      row = upsert(M::ThreadSummary, {room_id: event.room_id, event_id: relates[:event_id]})
      row.latest_reply_id = event.event_id
      row.reply_count = row.reply_count.to_i + 1
      row.save_changes(validate: false)
    end
  in {content: Events::RoomEncrypted}
    touch_latest(room, event)
  in {content: Events::Sticker}
    touch_latest(room, event)
  in {content: Events::Reaction}
    nil
  else
    nil
  end
end

def apply_room_account_data(room, room_id, event)
  M::AccountData.dataset.where(room_id: room_id, event_type: event.type).delete
  M::AccountData.new(room_id: room_id, event_type: event.type, content: event.content.to_h).save(validate: false)

  case event
  in {content: Events::Tag => content}
    tags = content.tags || {}
    room.favourite = tags.key?(FAVOURITE)
    room.low_priority = tags.key?(LOW_PRIORITY)
  in {content: Events::MarkedUnread => content}
    room.marked_unread = content.unread == true
    room.marked_unread_source = "stable"
  in {type: UNSTABLE_MARKED_UNREAD, content:}
    room.marked_unread = content.to_h[:unread] == true
    room.marked_unread_source = "unstable"
  in {content: Events::FullyRead => content}
    room.fully_read_event_id = content.event_id
  else
    nil
  end
end

TYPING = {}

TYPING_MUTEX = Mutex.new

def typing_in(room_id, me)
  TYPING_MUTEX.synchronize do
    Array(TYPING[room_id]) - [me]
  end
end

def apply_ephemeral(room, room_id, event)
  case event
  in {content: Events::Receipt => content}
    latest = nil

    content.to_h.each do |event_id, by_type|
      by_type.each do |receipt_type, members|
        members.each do |member_id, data|
          keys = {
            room_id: room_id, member_id: member_id.to_s,
            receipt_type: receipt_type.to_s, thread_id: data[:thread_id].to_s,
          }

          M::Receipt.dataset.where(**keys).delete
          M::Receipt.new(**keys, event_id: event_id.to_s, receipt_ts: data[:ts]).save(validate: false)

          latest = event_id.to_s
        end
      end
    end

    unless latest.nil?
      room.latest_receipt_event_id = latest
    end
  in {content: Events::Typing => content}
    TYPING_MUTEX.synchronize do
      users = Array(content.user_ids).map(&:to_s)

      if users.empty?
        TYPING.delete(room_id)
      else
        TYPING[room_id] = users
      end
    end
  else
    nil
  end
end

def apply_global_account_data(event)
  M::AccountData.dataset.where(room_id: M::AccountData::GLOBAL, event_type: event.type).delete
  M::AccountData.new(room_id: M::AccountData::GLOBAL, event_type: event.type, content: event.content.to_h).save(validate: false)

  case event
  in {content: Events::Direct => content}
    content.to_h.each_value do |room_ids|
      Array(room_ids).each do |room_id|
        M::Room.where(room_id: room_id.to_s).update(direct: true)
      end
    end
  in {content: Events::IgnoredUserList => content}
    Console.debug(self, "Ignored users updated.", count: (content.ignored_users || {}).size)
  in {content: Events::PushRules => content}
    muted = (content.to_h.dig(:global, :room) || [])
      .select{|rule| rule[:actions].to_a.empty?}
      .map{|rule| rule[:rule_id].to_s}

    M::Room.dataset.update(notification_mode: "default")

    unless muted.empty?
      M::Room.where(room_id: muted).update(notification_mode: "mute")
    end
  else
    nil
  end
end

def apply_presence(event)
  case event
  in {content: Events::Presence => content}
    upsert(M::GlobalProfile, {matrix_user_id: event[:sender]})
      .set(display_name: content.displayname, avatar_url: content.avatar_url)
      .save_changes(validate: false)
  else
    nil
  end
end

def apply_to_device(event)
  case event
  in {content: Events::RoomKey => content}
    store_inbound_session(content, event[:sender], false)
  in {content: Events::ForwardedRoomKey => content}
    store_inbound_session(content, event[:sender], true)
  in {content: Events::RoomKeyWithheld => content}
    M::WithheldKey.dataset.where(room_id: content.room_id, session_id: content.session_id).delete
    M::WithheldKey.new(
      room_id: content.room_id, session_id: content.session_id,
      sender_key: content.sender_key, code: content.code, reason: content.reason,
    ).save(validate: false)
  in {content: Events::RoomKeyRequest => content}
    upsert(M::KeyRequest, {request_id: content.request_id})
      .set(sent_out: false, info: {"action" => content.action}, content: content.to_h)
      .save_changes(validate: false)
  in {content: Events::SecretSend => content}
    upsert(M::SecretsInbox, {secret_name: content.request_id}).set(secret: content.secret).save_changes(validate: false)
  in {content: Events::KeyVerificationRequest => content}
    Matrix::Verification.requested!(content.transaction_id, event[:sender], content.to_h)
  in {content: Events::KeyVerificationReady => content}
    Matrix::Verification.ready!(content.transaction_id, content.to_h)
  in {content: Events::KeyVerificationStartReciprocateV => content}
    Matrix::Verification.reciprocated!(content.transaction_id, content.to_h)
  in {content: Events::KeyVerificationStartSasV | Events::KeyVerificationStart => content}
    accept_verification(content)
  in {content: Events::KeyVerificationAccept => content}
    Matrix::Verification.accepted!(content.transaction_id, content.to_h)
  in {content: Events::KeyVerificationKey => content}
    Matrix::Verification.receive_key!(content.transaction_id, content.key)
  in {content: Events::KeyVerificationMac => content}
    Matrix::Verification.receive_mac!(content.transaction_id, content.to_h)
  in {content: Events::KeyVerificationDone => content}
    Matrix::Verification.done!(content.transaction_id)
  in {content: Events::KeyVerificationCancel => content}
    Matrix::Verification.cancelled!(content.transaction_id, code: content.code.to_s, reason: content.reason)
  in {content: Events::RoomKeyBundle => content}
    upsert(M::RoomKeyBundle, {room_id: content.room_id, sender_user_id: event[:sender]})
      .set(state: "received", bundle: content.to_h)
      .save_changes(validate: false)
  else
    Console.debug(self, "Unhandled to-device event.", type: event.type)
  end
end

def accept_verification(content)
  flow = M::VerificationFlow.first(flow_id: content.transaction_id)

  if flow.nil?
    Console.warn(self, "A verification started which was never requested.", flow: content.transaction_id)
  elsif flow.started_by_us
    Console.debug(self, "Both sides started: ours wins.", flow: content.transaction_id)
  else
    Matrix::Verification.accept_start!(content.transaction_id, content.to_h)
  end
end

def store_inbound_session(content, sender, imported)
  upsert(M::MegolmInboundSession, {room_id: content.room_id, session_id: content.session_id}).set(
    sender_key: content.to_h[:sender_key] || sender,
    pickle: content.session_key,
    sender_data: {"sender" => sender},
    sender_data_type: imported ? "forwarded" : "device",
    imported: imported,
    backed_up: false,
  ).save_changes(validate: false)
end

def apply_room(registry, room_id, payload, membership, me)
  forgotten = Matrix::RoomActions.forgotten.include?(room_id)

  unless forgotten && membership == "leave"
    if forgotten
      Matrix::RoomActions.remember!(room_id)
    end

    apply_room!(registry, room_id, payload, membership, me)
  end
end

def apply_room!(registry, room_id, payload, membership, me)
  room = upsert(M::Room, {room_id: room_id})
  room.membership = membership

  stripped = membership == "invite"
  state = payload.dig(:state, :events) || payload.dig(:invite_state, :events) || []

  state.each do |raw|
    apply_state(room, registry.wrap(raw, room_id: room_id), stripped, me)
  end

  timeline = payload[:timeline] || {}

  (timeline[:events] || []).each do |raw|
    apply_timeline(room, registry.wrap(raw, room_id: room_id), me)
  end

  unless timeline[:prev_batch].to_s.empty?
    room.prev_batch = timeline[:prev_batch]

    if timeline[:limited]
      M::TimelineChunk.new(
        room_id: room_id, chunk_id: timeline[:prev_batch], kind: "gap", prev_token: timeline[:prev_batch],
      ).save(validate: false)
    end
  end

  counts = payload[:unread_notifications] || {}
  room.num_unread = counts[:notification_count].to_i
  room.num_notifications = counts[:notification_count].to_i
  room.unread_count = counts[:notification_count].to_i
  room.num_mentions = counts[:highlight_count].to_i
  room.highlight_count = counts[:highlight_count].to_i

  (payload[:unread_thread_notifications] || {}).each do |root, thread|
    upsert(M::ThreadSummary, {room_id: room_id, event_id: root.to_s}).set(
      info: {
        "notification_count" => thread[:notification_count].to_i,
        "highlight_count" => thread[:highlight_count].to_i,
      },
    ).save_changes(validate: false)
  end

  (payload.dig(:account_data, :events) || []).each do |raw|
    apply_room_account_data(room, room_id, registry.wrap(raw, room_id: room_id))
  end

  (payload.dig(:ephemeral, :events) || []).each do |raw|
    apply_ephemeral(room, room_id, registry.wrap(raw, room_id: room_id))
  end

  room.save_changes(validate: false)
end

def apply_devices(credential)
  rows = Matrix::Session.devices(credential)

  unless rows.nil?
    rows.each do |device|
      row = upsert(M::Device, {matrix_user_id: credential.matrix_user_id, device_id: device[:device_id].to_s})

      row.set(
        display_name: device[:display_name],
        last_seen_ts: device[:last_seen_ts],
        last_seen_ip: device[:last_seen_ip],
      )
      row.save_changes(validate: false)
    end
  end
end

def apply_batch(batch, me)
  registry = Events.registry(Matrix::Homeserver::VERSION)

  DB.transaction do
    batch.joined.each{|room_id, payload| apply_room(registry, room_id.to_s, payload, "join", me)}
    batch.invited.each{|room_id, payload| apply_room(registry, room_id.to_s, payload, "invite", me)}

    (batch.value.dig(:rooms, :leave) || {}).each do |room_id, payload|
      apply_room(registry, room_id.to_s, payload, "leave", me)
    end

    (batch.value.dig(:presence, :events) || []).each{|raw| apply_presence(registry.wrap(raw))}
    (batch.value.dig(:account_data, :events) || []).each{|raw| apply_global_account_data(registry.wrap(raw))}

    batch.to_device.each{|raw| apply_to_device(registry.wrap(raw))}

    batch.changed_devices.each do |user_id|
      upsert(M::TrackedUser, {matrix_user_id: user_id}).set(dirty: true).save_changes(validate: false)
    end

    if batch.changed_devices.map(&:to_s).include?(me)
      apply_devices(M::Credential.first)
    end

    batch.left_devices.each do |user_id|
      M::TrackedUser.where(matrix_user_id: user_id).delete
      M::Device.where(matrix_user_id: user_id).delete
    end

    counts = batch.one_time_keys_count

    unless counts.empty?
      M::DeviceState.first&.set(otk_count: counts[:signed_curve25519].to_i)&.save_changes(validate: false)
    end

    M::KV.sync_token = batch.next_batch
  end

  unless batch.empty?
    Console.debug(self, "Applied a batch.", joined: batch.joined.size, next_batch: batch.next_batch)
  end
end

def sync_loop
  waiting = false

  while true
    begin
      credential = M::Credential.first

      if credential&.usable?
        waiting = false

        Matrix::Session.open(credential) do |client, _credentials|
          since = M::KV.sync_token

          Console.info(self, "Starting sync.", user_id: credential.matrix_user_id, resumed: !since.nil?)

          apply_devices(credential)

          sync = client.sync(since: since, timeout: since.nil? ? 0 : SYNC_TIMEOUT)

          sync.each(retries: 8, timeout: SYNC_TIMEOUT) do |batch|
            apply_batch(batch, credential.matrix_user_id)
          end
        end
      else
        unless waiting
          waiting = true

          Console.info(self, "No session yet; waiting for a sign-in.")
        end

        sleep(2)
      end
    rescue Interrupt
      raise
    rescue StandardError => error
      Console.warn(self, "Sync stopped; restarting.", error: error)

      sleep(5)
    end
  end
end

Async do |task|
  task.async do
    sync_loop
  end

  Server
    .use(Ratalada::Contrib::Inertia::JsonParamsMiddleware)
    .use(Ratalada::Contrib::Vite::DevServerProxy)
    .use(Ratalada::Contrib::Inertia::Middleware)
    .use(Ratalada::Contrib::Inertia::CSRFMiddleware)
    .run do
      extend Ratalada::Contrib::Inertia

      Ratalada::Contrib::Router::FileBased
        .mount(self, File.expand_path("app", __dir__))
    end
end
