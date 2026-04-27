# Matrix Events Reference

> **Auto-generated** from the [Matrix Specification](https://spec.matrix.org/latest/)
> event schemas (`matrix-org/matrix-spec`). Do not edit by hand.
>
> Regenerate: `bin/fetch-matrix-schemas && ruby bin/generate-matrix-events-doc`

## How Matrix Events Work

Every event in Matrix is a JSON object with a common envelope:

```json
{
  "type": "m.room.message",
  "event_id": "$143273582443PhrSn:example.org",
  "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
  "sender": "@alice:example.org",
  "origin_server_ts": 1432735824653,
  "content": { ... },
  "unsigned": { "age": 1234 }
}
```

**State events** additionally have a `state_key` field and represent persistent
room configuration (name, topic, membership, power levels, etc.). The same
`(type, state_key)` pair is overwritten rather than appended.

**Message events** (no `state_key`) represent transient activity: messages sent,
reactions, redactions, stickers, calls.

**Ephemeral events** are not persisted and are delivered via `/sync` only
(typing indicators, read receipts, presence).

The `type` field determines what kind of event it is. For `m.room.message`
events, the `content.msgtype` sub-field further specifies the message type
(text, image, file, etc.).

### Application Service Transaction Format

An appservice receives events as HTTP `PUT` requests to
`/_matrix/app/v1/transactions/{txnId}` with a body like:

```json
{
  "events": [ ... array of event objects ... ]
}
```

---

## Table of Contents

- **[Room State Events](#room-state-events)**
  - [`m.room.avatar`](#mroomavatar)
  - [`m.room.canonical_alias`](#mroomcanonicalalias)
  - [`m.room.create`](#mroomcreate)
  - [`m.room.encryption`](#mroomencryption)
  - [`m.room.guest_access`](#mroomguestaccess)
  - [`m.room.history_visibility`](#mroomhistoryvisibility)
  - [`m.room.join_rules`](#mroomjoinrules)
  - [`m.room.member`](#mroommember)
  - [`m.room.name`](#mroomname)
  - [`m.room.pinned_events`](#mroompinnedevents)
  - [`m.room.policy`](#mroompolicy)
  - [`m.room.power_levels`](#mroompowerlevels)
  - [`m.room.server_acl`](#mroomserveracl)
  - [`m.room.third_party_invite`](#mroomthirdpartyinvite)
  - [`m.room.tombstone`](#mroomtombstone)
  - [`m.room.topic`](#mroomtopic)

- **[Room Message Events](#room-message-events)**
  - [`m.reaction`](#mreaction)
  - [`m.room.message`](#mroommessage)
    - [`m.audio`](#maudio)
    - [`m.emote`](#memote)
    - [`m.file`](#mfile)
    - [`m.image`](#mimage)
    - [`m.key.verification.request`](#mkeyverificationrequest)
    - [`m.location`](#mlocation)
    - [`m.notice`](#mnotice)
    - [`m.server_notice`](#mservernotice)
    - [`m.text`](#mtext)
    - [`m.video`](#mvideo)
  - [`m.room.redaction`](#mroomredaction)
  - [`m.sticker`](#msticker)

- **[Ephemeral Events](#ephemeral-events)**
  - [`m.presence`](#mpresence)
  - [`m.receipt`](#mreceipt)
  - [`m.typing`](#mtyping)

- **[Space Events](#space-events)**
  - [`m.space.child`](#mspacechild)
  - [`m.space.parent`](#mspaceparent)

- **[VoIP Events](#voip-events)**
  - [`m.call.answer`](#mcallanswer)
  - [`m.call.candidates`](#mcallcandidates)
  - [`m.call.hangup`](#mcallhangup)
  - [`m.call.invite`](#mcallinvite)
  - [`m.call.negotiate`](#mcallnegotiate)
  - [`m.call.reject`](#mcallreject)
  - [`m.call.sdp_stream_metadata_changed`](#mcallsdpstreammetadatachanged)
  - [`m.call.select_answer`](#mcallselectanswer)

- **[Moderation Policy Events](#moderation-policy-events)**
  - [`m.policy.rule.room`](#mpolicyruleroom)
  - [`m.policy.rule.server`](#mpolicyruleserver)
  - [`m.policy.rule.user`](#mpolicyruleuser)

- **[Account Data & Other Events](#account-data-other-events)**
  - [`m.accepted_terms`](#macceptedterms)
  - [`m.direct`](#mdirect)
  - [`m.fully_read`](#mfullyread)
  - [`m.identity_server`](#midentityserver)
  - [`m.ignored_user_list`](#mignoreduserlist)
  - [`m.invite_permission_config`](#minvitepermissionconfig)
  - [`m.marked_unread`](#mmarkedunread)
  - [`m.push_rules`](#mpushrules)
  - [`m.recent_emoji`](#mrecentemoji)
  - [`m.room.encrypted`](#mroomencrypted)
  - [`m.tag`](#mtag)

- **[Key Verification Events](#key-verification-events)**
  - [`m.key.verification.accept`](#mkeyverificationaccept)
  - [`m.key.verification.cancel`](#mkeyverificationcancel)
  - [`m.key.verification.done`](#mkeyverificationdone)
  - [`m.key.verification.key`](#mkeyverificationkey)
  - [`m.key.verification.m.relates_to`](#mkeyverificationmrelatesto)
  - [`m.key.verification.mac`](#mkeyverificationmac)
  - [`m.key.verification.ready`](#mkeyverificationready)
  - [`m.key.verification.request`](#mkeyverificationrequest)
  - [`m.key.verification.start`](#mkeyverificationstart)
    - [`m.reciprocate.v1`](#mreciprocatev1)
    - [`m.sas.v1`](#msasv1)

- **[E2E & Key Management Events](#e2e-key-management-events)**
  - [`m.dummy`](#mdummy)
  - [`m.forwarded_room_key`](#mforwardedroomkey)
  - [`m.key_backup`](#mkeybackup)
  - [`m.room_key`](#mroomkey)
  - [`m.room_key.withheld`](#mroomkeywithheld)
  - [`m.room_key_request`](#mroomkeyrequest)
  - [`m.secret.request`](#msecretrequest)
  - [`m.secret.send`](#msecretsend)


---

## Event Type Reference


## Room State Events


### `m.room.avatar`

A picture that is associated with the room. This can be displayed alongside the room information.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `info` | `object` | no | Metadata about the image referred to in `url`. |
| `url` | `string` | no | The URL to the image. If this property is not present, the room has no avatar. This can be useful
to remove a previous room avatar. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.avatar",
  "state_key": "",
  "content": {
    "info": {
      "h": 398,
      "w": 394,
      "mimetype": "image/jpeg",
      "size": 31037
    },
    "url": "mxc://example.org/JWEIFJgwEIhweiWJE"
  }
}
```

</details>

---


### `m.room.canonical_alias`

This event is used to inform the room about which alias should be
considered the canonical one, and which other aliases point to the room.
This could be for display purposes or as suggestion to users which alias
to use to advertise and access the room.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `alias` | `string` | no | The canonical alias for the room. If not present, null, or empty the
room should be considered to have no canonical alias. |
| `alt_aliases` | `array` | no | Alternative aliases the room advertises. This list can have aliases
despite the `alias` field being null, empty, or otherwise not present. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.canonical_alias",
  "state_key": "",
  "content": {
    "alias": "#somewhere:localhost",
    "alt_aliases": [
      "#somewhere:example.org",
      "#myroom:example.com"
    ]
  }
}
```

</details>

---


### `m.room.create`

This is the first event in a room and cannot be changed. It acts as the root of all other events.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `creator` | `string` | no | The `user_id` of the room creator. **Required** for, and only present in, room versions 1 - 10. Starting with
room version 11 the event `sender` should be used instead. |
| `m.federate` | `boolean` | no | Whether users on other servers can join this room. Defaults to `true` if key does not exist. |
| `room_version` | `string` | no | The version of the room. Defaults to `"1"` if the key does not exist. |
| `type` | `string` | no | Optional [room type](/client-server-api/#types) to denote a room's intended function outside of traditional
conversation. Unspecified room types are possible using [Namespaced Identifiers](/appendices/#common-namespaced-identifier-grammar). |
| `predecessor` | `object` | no | A reference to the room this room replaces, if the previous room was upgraded. Contains: `room_id` (string): The ID of the old room.; `event_id` (string): The event ID of the last known event in the old room, if known. If not set, clients SHOULD search for the `m.room.tombstone` state event to navigate to
when directing the user to the old room (potentially after joining the room, if requested
by the user).. |
| `additional_creators` | `array` | no | Starting with room version 12, the other user IDs to consider as creators for the room in
addition to the `sender` of this event. Each string MUST be a valid [user ID](/appendices#user-identifiers)
for the room version. When not present or empty, the `sender` of the event is the only creator. In room versions 1 through 11, this field serves no purpose and is not validated. Clients
SHOULD NOT attempt to parse or understand this field in these room versions. **Note**: Because `creator` was removed in room version 11, the field is not used to determine
which user(s) are room creators in room version 12 and beyond either. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.create",
  "state_key": "",
  "content": {
    "room_version": "11",
    "m.federate": true,
    "predecessor": {
      "event_id": "$something:example.org",
      "room_id": "!oldroom:example.org"
    }
  }
}
```

</details>

---


### `m.room.encryption`

Defines how messages sent in this room should be encrypted.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `algorithm` | `string` | **yes** | The encryption algorithm to be used to encrypt messages sent in this
room. One of: `m.megolm.v1.aes-sha2`. |
| `rotation_period_ms` | `integer` | no | How long the session should be used before changing it. `604800000`
(a week) is the recommended default. |
| `rotation_period_msgs` | `integer` | no | How many messages should be sent before changing the session. `100` is the
recommended default. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.encryption",
  "state_key": "",
  "content": {
    "algorithm": "m.megolm.v1.aes-sha2",
    "rotation_period_ms": 604800000,
    "rotation_period_msgs": 100
  }
}
```

</details>

---


### `m.room.guest_access`

This event controls whether guest users are allowed to join rooms. If this event is absent, servers should act as if it is present and has the guest_access value "forbidden".

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `guest_access` | `string` | **yes** | Whether guests can join the room. One of: `can_join`, `forbidden`. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.guest_access",
  "state_key": "",
  "content": {
    "guest_access": "can_join"
  }
}
```

</details>

---


### `m.room.history_visibility`

This event controls whether a user can see the events that happened in a room from before they joined.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `history_visibility` | `string` | **yes** | Who can see the room history. One of: `invited`, `joined`, `shared`, `world_readable`. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.history_visibility",
  "state_key": "",
  "content": {
    "history_visibility": "shared"
  }
}
```

</details>

---


### `m.room.join_rules`

A room may have one of the following designations:
* `public` - anyone can join the room without any prior action.
* `invite` - a user must first receive an invite from someone already in the room
  in order to join.
* `knock` - a user can request an invite to the room. They can be allowed (invited)
  or denied (kicked/banned) access. Otherwise, users need to be invited in. Only
  available in rooms [which support knocking](/rooms/#feature-matrix).
* `restricted` - anyone able to satisfy at least one of the allow conditions is
  able to join the room without prior action. Otherwise, an invite is required.
  Only available in rooms [which support the join rule](/rooms/#feature-matrix).
* `knock_restricted` - a user can request an invite using the same functions offered
  by the `knock` join rule, or can attempt to join having satisfied an allow condition
  per the `restricted` join rule. Only available in rooms
  [which support the join rule](/rooms/#feature-matrix).
* `private` - reserved without implementation. No significant meaning.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `join_rule` | `string` | **yes** | The type of rules used for users wishing to join this room. One of: `public`, `knock`, `invite`, `private`, `restricted`, `knock_restricted`. |
| `allow` | `array` | no | For `restricted` rooms, the conditions the user will be tested against. The
user needs only to satisfy one of the conditions to join the `restricted`
room. If the user fails to meet any condition, or the condition is unable
to be confirmed as satisfied, then the user requires an invite to join the
room. Improper or no `allow` conditions on a `restricted` join rule imply
the room is effectively invite-only (no conditions can be satisfied). |

<details><summary>Example</summary>

```json
{
  "type": "m.room.join_rules",
  "state_key": "",
  "content": {
    "join_rule": "public"
  }
}
```

</details>

---


### `m.room.member`

Adjusts the membership state for a user in a room. It is preferable to use the membership APIs
(`/rooms/<room id>/invite` etc) when performing membership actions rather than adjusting the
state directly as there are a restricted set of valid transformations. For example, user A cannot
force user B to join a room, and trying to force this state change directly will fail.

The following membership states are specified:

- `invite` - The user has been invited to join a room, but has not yet joined it. They may not
  participate in the room until they join.
- `join` - The user has joined the room (possibly after accepting an invite), and may participate
  in it.
- `leave` - The user was once joined to the room, but has since left (possibly by choice, or
  possibly by being kicked).
- `ban` - The user has been banned from the room, and is no longer allowed to join it until they
  are un-banned from the room (by having their membership state set to a value other than `ban`).
- `knock` - The user has knocked on the room, requesting permission to participate. They may not
  participate in the room until they join.

The `third_party_invite` property will be set if this invite is an `invite` event and is the
successor of an [`m.room.third_party_invite`](/client-server-api/#mroomthird_party_invite) event,
and absent otherwise.

This event may also include an `invite_room_state` key inside the event's `unsigned` data.
If present, this contains an array of [stripped state events](/client-server-api/#stripped-state)
to assist the receiver in identifying the room.

The user for which a membership applies is represented by the `state_key`. Under some conditions,
the `sender` and `state_key` may not match - this may be interpreted as the `sender` affecting
the membership state of the `state_key` user.

The `membership` for a given user can change over time. The table below represents the various changes
over time and how clients and servers must interpret those changes. Previous membership can be retrieved
from the `prev_content` object on an event. If not present, the user's previous membership must be assumed
as `leave`.

|                   | to `invite`          | to `join`                              | to `leave`                                                                                                                              | to `ban`                    | to `knock`           |
|-------------------|----------------------|----------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------|-----------------------------|----------------------|
| **from `invite`** | No change.           | User joined the room.                  | If the `state_key` is the same as the `sender`, the user rejected the invite. Otherwise, the `state_key` user had their invite revoked. | User was banned.            | User is re-knocking. |
| **from `join`**   | Must never happen.   | `displayname` or `avatar_url` changed. | If the `state_key` is the same as the `sender`, the user left. Otherwise, the `state_key` user was kicked.                              | User was kicked and banned. | Must never happen.   |
| **from `leave`**  | New invitation sent. | User joined.                           | No change.                                                                                                                              | User was banned.            | User is knocking.    |
| **from `ban`**    | Must never happen.   | Must never happen.                     | User was unbanned.                                                                                                                      | No change.                  | Must never happen.   |
| **from `knock`**  | Knock accepted.      | Must never happen.                     | If the `state_key` is the same as the `sender`, the user retracted the knock. Otherwise, the `state_key` user had their knock denied.   | User was banned.            | No change.           |

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `avatar_url` | `string` | no | The avatar URL for this user, if any. |
| `displayname` | `string | null` | no | The display name for this user, if any. |
| `membership` | `string` | **yes** | The membership state of the user. One of: `invite`, `join`, `knock`, `leave`, `ban`. |
| `is_direct` | `boolean` | no | Flag indicating if the room containing this event was created with the intention of being
a direct chat. See [Direct Messaging](/client-server-api/#direct-messaging). |
| `join_authorised_via_users_server` | `string` | no | Usually found on `join` events, this field is used to denote which homeserver (through
representation of a user with sufficient power level) authorised the user's join. More
information about this field can be found in the [Restricted Rooms Specification](/client-server-api/#restricted-rooms). Client and server implementations should be aware of the [signing implications](/rooms/v8/#authorization-rules)
of including this field in further events: in particular, the event must be signed by the
server which owns the user ID in the field. When copying the membership event's `content`
(for profile updates and similar) it is therefore encouraged to exclude this field in the
copy, as otherwise the event might fail event authorization. |
| `reason` | `string` | no | Optional user-supplied text for why their membership has changed. For kicks and bans,
this is typically the reason for the kick or ban. For other membership changes, this is a
way for the user to communicate their intent without having to send a message to the
room, such as in a case where Bob rejects an invite from Alice about an upcoming concert,
but can't make it that day. Clients are not recommended to show this reason to users when receiving an invite due to
the potential for spam and abuse. Hiding the reason behind a button or other component is
recommended. |
| `third_party_invite` | `object` | no | A third-party invite, if this `m.room.member` is the successor to an
[`m.room.third_party_invite`](/client-server-api/#mroomthird_party_invite)
event. Contains: `display_name` (string): A name which can be displayed to represent the user instead of their
third-party identifier; `signed` (object): . |

<details><summary>Example</summary>

```json
{
  "state_key": "@alice:example.org",
  "sender": "@alice:example.org",
  "type": "m.room.member",
  "content": {
    "membership": "join",
    "avatar_url": "mxc://example.org/SEsfnsuifSDFSSEF",
    "displayname": "Alice Margatroid",
    "reason": "Looking for support"
  }
}
```

</details>

---


### `m.room.name`

A room has an opaque room ID which is not human-friendly to read. A room
alias is human-friendly, but not all rooms have room aliases. The room name
is a human-friendly string designed to be displayed to the end-user. The
room name is not unique, as multiple rooms can have the same room name set.

If a room has an `m.room.name` event with an absent, null, or empty `name`
field, it should be treated the same as a room with no `m.room.name` event.

An event of this type is automatically created when creating a room using
`/createRoom` with the `name` key.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `name` | `string` | **yes** | The name of the room. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.name",
  "state_key": "",
  "content": {
    "name": "The room name"
  }
}
```

</details>

---


### `m.room.pinned_events`

This event is used to "pin" particular events in a room for other participants to review later. The order of the pinned events is guaranteed and based upon the order supplied in the event. Clients should be aware that the current user may not be able to see some of the events pinned due to visibility settings in the room. Clients are responsible for determining if a particular event in the pinned list is displayable, and have the option to not display it if it cannot be pinned in the client.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `pinned` | `array` | **yes** | An ordered list of event IDs to pin. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.pinned_events",
  "state_key": "",
  "content": {
    "pinned": [
      "$someevent:example.org"
    ]
  }
}
```

</details>

---


### `m.room.policy`

A [Policy Server](/client-server-api/#policy-servers) configuration. If invalid
or not set, the room does not use a Policy Server.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `via` | `string` | **yes** | The server name to use as a Policy Server. MUST have a joined user in
the room. |
| `public_keys` | `object` | **yes** | The unpadded base64-encoded public keys for the Policy Server. MUST contain at
least `ed25519`. Contains: `ed25519` (string): The unpadded base64-encoded ed25519 public key for the Policy Server.. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.policy",
  "state_key": "",
  "content": {
    "via": "policy.example.org",
    "public_keys": {
      "ed25519": "6yhHGKhCiXTSEN2ksjV7kX_N6rBQZ3Xb-M7LlC6NS-s"
    }
  }
}
```

</details>

---


### `m.room.power_levels`

This event specifies the minimum level a user must have in order to perform a
certain action. It also specifies the levels of each user in the room.

If a `user_id` is in the `users` list, then that `user_id` has the
associated power level. Otherwise they have the default level
`users_default`. If `users_default` is not supplied, it is assumed to be
0. If the room contains no `m.room.power_levels` event, the room's creator has
a power level of 100, and all other users have a power level of 0.

Except for membership events and redactions, the level required to
send a certain event is governed purely by `events`, `state_default`
and `events_default`. If an event type is specified in `events`, then
the user must have at least the level specified in order to send that
event. If the event type is not supplied, it defaults to `events_default`
for message events and `state_default` for state events.

If there is no `state_default` in the `m.room.power_levels` event, or
there is no `m.room.power_levels` event, the `state_default` is 50.
If there is no `events_default` in the `m.room.power_levels` event,
or there is no `m.room.power_levels` event, the `events_default` is 0.

Membership events are not subject to `events`, `events_default`, or
`state_default`. Instead, the power level required to invite a user
to the room, kick a user from the room, or ban a user from the room
is defined by `invite`, `kick`, and `ban`, respectively. The levels
for `kick` and `ban` default to 50 if they are not specified in the
`m.room.power_levels` event, or if the room contains no
`m.room.power_levels` event. `invite` defaults to 0 in either case.
Other membership values are handled during event authorization. See
the authorization rules in [room versions](/rooms) for further details.

For redactions of a user's own events, the required power level is
determined by the `m.room.redaction` event power level, as per `events`
and `events_default`. The power level required to redact an event sent
by another user is _additionally_ governed by `redact`. The level for
`redact` defaults to 50 if it is not specified in the `m.room.power_levels`
event, or if the room contains no `m.room.power_levels` event.

**Note:**

The allowed range for power level values is `[-(2**53)+1, (2**53)-1]`,
as required by the [Canonical JSON specification](/appendices/#canonical-json).

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `ban` | `integer` | no | The level required to ban a user. Defaults to 50 if unspecified. |
| `events` | `object` | no | The level required to send specific event types. This is a mapping from event type to power level required. Though not a default, when the server sends the initial power levels event during [room creation](/client-server-api#creation)
in [room versions](/rooms) 12 and higher, the `m.room.tombstone` event MUST be explicitly defined and given
a power level higher than `state_default`. For example, power level 150. Clients may override this using the
described `power_level_content_override` field. |
| `events_default` | `integer` | no | The default level required to send message events. Can be
overridden by the `events` key.  Defaults to 0 if unspecified. |
| `invite` | `integer` | no | The level required to invite a user. Defaults to 0 if unspecified. |
| `kick` | `integer` | no | The level required to kick a user. Defaults to 50 if unspecified. |
| `redact` | `integer` | no | The level required to redact an event sent by another user. Defaults to 50 if unspecified. |
| `state_default` | `integer` | no | The default level required to send state events. Can be overridden
by the `events` key. Defaults to 50 if unspecified. |
| `users` | `object` | no | The power levels for specific users. This is a mapping from `user_id` to power level for that user. **Note**: In [room versions](/rooms) 12 and higher it is not permitted to specify the room creators here. |
| `users_default` | `integer` | no | The power level for users in the room whose `user_id` is not mentioned in the `users` key. Defaults to 0 if
unspecified. **Note**: In [room versions](/rooms) 1 through 11, when there is no `m.room.power_levels`
event in the room, the room creator has a power level of 100, and all other users have a
power level of 0. **Note**: In room versions 12 and higher, room creators have infinite power level regardless
of the existence of `m.room.power_levels` in the room. When `m.room.power_levels` is not
in the room however, all other users have a power level of 0. |
| `notifications` | `object` | no | The power level requirements for specific notification types.
This is a mapping from `key` to power level for that notifications key. Contains: `room` (integer): The level required to trigger an `@room` notification. Defaults to 50 if unspecified.. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.power_levels",
  "state_key": "",
  "content": {
    "ban": 50,
    "events": {
      "m.room.name": 100,
      "m.room.power_levels": 100
    },
    "events_default": 0,
    "invite": 50,
    "kick": 50,
    "redact": 50,
    "state_default": 50,
    "users": {
      "@example:localhost": 100
    },
    "users_default": 0,
    "notifications": {
      "room": 20
    }
  }
}
```

</details>

---


### `m.room.server_acl`

An event to indicate which servers are permitted to participate in the
room. Server ACLs may allow or deny groups of hosts. All servers participating
in the room, including those that are denied, are expected to uphold the
server ACL. Servers that do not uphold the ACLs MUST be added to the denied hosts
list in order for the ACLs to remain effective.

The `allow` and `deny` lists are lists of [glob-style patterns](/appendices#glob-style-matching).
When comparing against the server ACLs, the suspect server's port
number must not be considered. Therefore `evil.com`, `evil.com:8448`, and
`evil.com:1234` would all match rules that apply to `evil.com`, for example.

The ACLs are applied to servers when they make requests, and are applied in
the following order:

1. If there is no `m.room.server_acl` event in the room state, allow.
2. If the server name is an IP address (v4 or v6) literal, and `allow_ip_literals`
   is present and `false`, deny.
3. If the server name matches an entry in the `deny` list, deny.
4. If the server name matches an entry in the `allow` list, allow.
5. Otherwise, deny.

**Note:**
Server ACLs do not restrict the events relative to the room DAG via authorisation
rules, but instead act purely at the network layer to determine which servers are
allowed to connect and interact with a given room.

**Warning:**
Failing to provide an `allow` rule of some kind will prevent **all**
servers from participating in the room, including the sender. This renders
the room unusable. A common allow rule is `[ "*" ]` which would still
permit the use of the `deny` list without losing the room.

**Warning:**
All compliant servers must implement server ACLs.  However, legacy or noncompliant
servers exist which do not uphold ACLs, and these MUST be manually appended to
the denied hosts list when setting an ACL to prevent them from leaking events from
banned servers into a room. Currently, the only way to determine noncompliant hosts is
to check the `prev_events` of leaked events, therefore detecting servers which
are not upholding the ACLs. Server versions can also be used to try to detect hosts that
will not uphold the ACLs, although this is not comprehensive. Server ACLs were added
in Synapse v0.32.0, although other server implementations and versions exist in the world.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `allow_ip_literals` | `boolean` | no | True to allow server names that are IP address literals. False to
deny. Defaults to `true` if missing or otherwise not a boolean. This is strongly recommended to be set to `false` as servers running
with IP literal names are strongly discouraged in order to require
legitimate homeservers to be backed by a valid registered domain name. |
| `allow` | `array` | no | The server names to allow in the room, excluding any port information.
Each entry is interpreted as a [glob-style pattern](/appendices#glob-style-matching). **This defaults to an empty list when not provided, effectively disallowing
every server.** |
| `deny` | `array` | no | The server names to disallow in the room, excluding any port information.
Each entry is interpreted as a [glob-style pattern](/appendices#glob-style-matching). This defaults to an empty list when not provided. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.server_acl",
  "state_key": "",
  "content": {
    "allow_ip_literals": false,
    "allow": [
      "*"
    ],
    "deny": [
      "*.evil.com",
      "evil.com"
    ]
  }
}
```

</details>

---


### `m.room.third_party_invite`

Acts as an `m.room.member` invite event, where there isn't a target user_id to
invite. This event contains a token and a public key whose private key must be
used to sign the token. Any user who can present that signature may use this
invitation to join the target room.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `display_name` | `string` | **yes** | A user-readable string which represents the user who has been invited.
This should not contain the user's third-party ID, as otherwise when
the invite is accepted it would leak the association between the
matrix ID and the third-party ID. |
| `key_validity_url` | `string` | **yes** | A URL which can be fetched, with querystring public_key=public_key, to
validate whether the key has been revoked. The URL must return a JSON
object containing a boolean property named 'valid'. |
| `public_key` | `string` | **yes** | An Ed25519 key with which the token must be signed (though a signature
from any entry in `public_keys` is also sufficient). The key is encoded using [Unpadded Base64](/appendices/#unpadded-base64),
using the standard or URL-safe alphabets. This exists for backwards compatibility. |
| `public_keys` | `array` | no | Keys with which the token may be signed. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.third_party_invite",
  "state_key": "pc98",
  "content": {
    "display_name": "Alice Margatroid",
    "key_validity_url": "https://magic.forest/verifykey",
    "public_key": "abc123",
    "public_keys": [
      {
        "public_key": "def456",
        "key_validity_url": "https://magic.forest/verifykey"
      }
    ]
  }
}
```

</details>

---


### `m.room.tombstone`

A state event signifying that a room has been upgraded to a different room version, and that clients should go there.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | A server-defined message. |
| `replacement_room` | `string` | **yes** | The room ID of the new room the client should be visiting. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.tombstone",
  "state_key": "",
  "content": {
    "body": "This room has been replaced",
    "replacement_room": "!newroom:example.org"
  }
}
```

</details>

---


### `m.room.topic`

A topic is a short message detailing what is currently being discussed
in the room.  It can also be used as a way to display extra information
about the room, which may not be suitable for the room name. The room
topic can also be set when creating a room using
[`/createRoom`](client-server-api/#post_matrixclientv3createroom), either
with the `topic` key or by specifying a full event in `initial_state`.

If the `topic` property is absent, null, or empty then the topic is unset. In other words,
an empty `topic` property effectively resets the room to having no topic.

In order to prevent formatting abuse in room topics, clients SHOULD
limit the length of topics during both entry and display, for instance,
by capping the number of displayed lines. Additionally, clients SHOULD
ignore things like headings and enumerations (or format them as regular
text).

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `topic` | `string` | **yes** | The topic in plain text. This SHOULD duplicate the content of the `text/plain`
representation in `m.topic` if any exists. |
| `m.topic` | `object` | no | Textual representation of the room topic in different mimetypes. Contains: `m.text` (object): . |

<details><summary>Example</summary>

```json
{
  "type": "m.room.topic",
  "state_key": "",
  "content": {
    "m.topic": {
      "m.text": [
        {
          "mimetype": "text/html",
          "body": "An <em>interesting</em> room topic"
        },
        {
          "body": "An interesting room topic"
        }
      ]
    },
    "topic": "An interesting room topic"
  }
}
```

</details>

---


## Room Message Events


### `m.reaction`

Indicates a reaction to a previous event.

Has no defined `content` properties of its own. Its only purpose is to hold an
[`m.relates_to`](/client-server-api/#definition-mrelates_to) property.

Since they contain no content other than `m.relates_to`, `m.reaction` events
are normally not encrypted, as there would be no benefit in doing so.

- **Kind:** Room message event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `m.relates_to` | `object` | no | Indicates the event being reacted to, and the type of reaction. Contains: `rel_type` (string): ; `event_id` (string): The event ID of the event that this is a reaction to.; `key` (string): The reaction being made, usually an emoji. If this is an emoji, it should include the unicode emoji
presentation selector (`\uFE0F`) for codepoints which allow it
(see the [emoji variation sequences
list](https://www.unicode.org/Public/UCD/latest/ucd/emoji/emoji-variation-sequences.txt)).. |

<details><summary>Example</summary>

```json
{
  "type": "m.reaction",
  "content": {
    "m.relates_to": {
      "rel_type": "m.annotation",
      "event_id": "$some_event_id",
      "key": "👍"
    }
  }
}
```

</details>

---


### `m.room.message`

This event is used when sending messages in a room. Messages are not limited to be text. The `msgtype` key outlines the type of message, e.g. text, audio, image, video, etc. The `body` key is text and MUST be used with every kind of `msgtype` as a fallback mechanism for when a client cannot render a message. This allows clients to display *something* even if it is just plain text.

- **Kind:** Room message event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | The textual representation of this message. |
| `msgtype` | `string` | **yes** | The type of message, e.g. `m.image`, `m.text` |

#### Message Types (`content.msgtype`)

##### `m.audio`

This message represents a single audio clip.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | If `filename` is not set or the value of both properties are
identical, this is the filename of the original upload. Otherwise,
this is a caption for the audio. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`, when it acts as a caption. This
is required if `format` is specified. |
| `filename` | `string` | no | The original filename of the uploaded file. |
| `info` | `object` | no | Metadata for the audio clip referred to in `url`. Contains: `duration` (integer): The duration of the audio in milliseconds.; `mimetype` (string): The mimetype of the audio e.g. `audio/aac`.; `size` (integer): The size of the audio clip in bytes.. |
| `msgtype` | `string` | **yes** |  One of: `m.audio`. |
| `url` | `string` | no | Required if the file is unencrypted. The URL (typically [`mxc://` URI](/client-server-api/#matrix-content-mxc-uris))
to the audio clip. |
| `file` | `object` | no | Required if the file is encrypted. Information on the encrypted
file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments). |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "Bee Gees - Stayin' Alive",
    "url": "mxc://example.org/ffed755USFFxlgbQYZGtryd",
    "info": {
      "duration": 2140786,
      "size": 1563685,
      "mimetype": "audio/mpeg"
    },
    "msgtype": "m.audio"
  }
}
```

</details>

##### `m.emote`

This message is similar to `m.text` except that the sender is 'performing' the action contained in the `body` key, similar to `/me` in IRC. This message should be prefixed by the name of the sender. This message could also be represented in a different colour to distinguish it from regular `m.text` messages.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | The emote action to perform. |
| `msgtype` | `string` | **yes** |  One of: `m.emote`. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`. This is required if `format`
is specified. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "thinks this is an example emote",
    "msgtype": "m.emote",
    "format": "org.matrix.custom.html",
    "formatted_body": "thinks <b>this</b> is an example emote"
  }
}
```

</details>

##### `m.file`

This message represents a generic file.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | If `filename` is not set or the value of both properties are
identical, this is the filename of the original upload. Otherwise,
this is a caption for the file. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`, when it acts as a caption. This
is required if `format` is specified. |
| `filename` | `string` | no | The original filename of the uploaded file. |
| `info` | `object` | no | Information about the file referred to in `url`. Contains: `mimetype` (string): The mimetype of the file e.g. `application/msword`.; `size` (integer): The size of the file in bytes.; `thumbnail_url` (string): The URL to the thumbnail of the file. Only present if the
thumbnail is unencrypted.; `thumbnail_file` (object): Information on the encrypted thumbnail file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments).
Only present if the thumbnail is encrypted.; `thumbnail_info` (object): Metadata about the image referred to in `thumbnail_url`.. |
| `msgtype` | `string` | **yes** |  One of: `m.file`. |
| `url` | `string` | no | Required if the file is unencrypted. The URL (typically [`mxc://` URI](/client-server-api/#matrix-content-mxc-uris))
to the file. |
| `file` | `object` | no | Required if the file is encrypted. Information on the encrypted
file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments). |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "something-important.doc",
    "filename": "something-important.doc",
    "info": {
      "mimetype": "application/msword",
      "size": 46144
    },
    "msgtype": "m.file",
    "url": "mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe"
  }
}
```

</details>

##### `m.image`

This message represents a single image and an optional thumbnail.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | If `filename` is not set or the value of both properties are
identical, this is the filename of the original upload. Otherwise,
this is a caption for the image. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`, when it acts as a caption. This
is required if `format` is specified. |
| `filename` | `string` | no | The original filename of the uploaded file. |
| `info` | `object` | no | Metadata about the image referred to in `url`. |
| `msgtype` | `string` | **yes** |  One of: `m.image`. |
| `url` | `string` | no | Required if the file is unencrypted. The URL (typically [`mxc://` URI](/client-server-api/#matrix-content-mxc-uris))
to the image. |
| `file` | `object` | no | Required if the file is encrypted. Information on the encrypted
file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments). |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "filename.jpg",
    "info": {
      "h": 398,
      "w": 394,
      "mimetype": "image/jpeg",
      "size": 31037,
      "is_animated": false
    },
    "url": "mxc://example.org/JWEIFJgwEIhweiWJE",
    "msgtype": "m.image"
  }
}
```

</details>

##### `m.key.verification.request`

Requests a key verification in a room.  When requesting a key verification using to-device messaging, an event with type [`m.key.verification.request`](/client-server-api/#mkeyverificationrequest) should be used.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | no | A fallback message to alert users that their client does not support
the key verification framework, and that they should use a different method
to verify keys.  For example, "Alice is requesting to verify keys with you.
However, your client does not support this method, so you will need to use
the legacy method of key verification." Clients that do support the key verification framework should hide the body
and instead present the user with an interface to accept or reject the key
verification. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`. This is required if `format` is
specified.  As with the `body`, clients that do support the key
verification framework should hide the formatted body and instead
present the user with an interface to accept or reject the key
verification. |
| `from_device` | `string` | **yes** | The device ID which is initiating the request. |
| `methods` | `array` | **yes** | The verification methods supported by the sender. |
| `to` | `string` | **yes** | The user that the verification request is intended for.  Users who
are not named in this field and who did not send this event should
ignore all other events that have an `m.reference` relationship with
this event. |
| `msgtype` | `string` | **yes** |  One of: `m.key.verification.request`. |

<details><summary>Example</summary>

```json
{
  "event_id": "$143273582443PhrSn:example.org",
  "origin_server_ts": 1432735824653,
  "room_id": "!jEsUZKDJdhlrceRyVU:example.org",
  "sender": "@alice:example.org",
  "type": "m.room.message",
  "unsigned": {
    "age": 1234
  },
  "content": {
    "body": "Alice is requesting to verify your device, but your client does not support verification, so you may need to use a different verification method.",
    "from_device": "AliceDevice2",
    "methods": [
      "m.sas.v1"
    ],
    "to": "@bob:example.org",
    "msgtype": "m.key.verification.request"
  }
}
```

</details>

##### `m.location`

This message represents a real-world location.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | A description of the location e.g. 'Big Ben, London, UK', or some kind of content description for accessibility e.g. 'location attachment'. |
| `geo_uri` | `string` | **yes** | A [geo URI (RFC5870)](https://datatracker.ietf.org/doc/html/rfc5870) representing this location. |
| `msgtype` | `string` | **yes** |  One of: `m.location`. |
| `info` | `object` | no |  Contains: `thumbnail_url` (string): The URL to a thumbnail of the location being represented.
Only present if the thumbnail is unencrypted.; `thumbnail_file` (object): Information on the encrypted thumbnail file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments).
Only present if the thumbnail is encrypted.; `thumbnail_info` (object): Metadata about the image referred to in `thumbnail_url`.. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "Big Ben, London, UK",
    "geo_uri": "geo:51.5008,0.1247",
    "info": {
      "thumbnail_url": "mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe",
      "thumbnail_info": {
        "mimetype": "image/jpeg",
        "size": 46144,
        "w": 300,
        "h": 300
      }
    },
    "msgtype": "m.location"
  }
}
```

</details>

##### `m.notice`

The `m.notice` type is primarily intended for responses from automated clients. An `m.notice` message must be treated the same way as a regular `m.text` message with two exceptions. Firstly, clients should present `m.notice` messages to users in a distinct manner, and secondly, `m.notice` messages must never be automatically responded to. This helps to prevent infinite-loop situations where two automated clients continuously exchange messages.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | The notice text to send. |
| `msgtype` | `string` | **yes** |  One of: `m.notice`. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`. This is required if `format`
is specified. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "This is an example notice",
    "msgtype": "m.notice",
    "format": "org.matrix.custom.html",
    "formatted_body": "This is an <strong>example</strong> notice"
  }
}
```

</details>

##### `m.server_notice`

Represents a server notice for a user.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | A human-readable description of the notice. |
| `msgtype` | `string` | **yes** |  One of: `m.server_notice`. |
| `server_notice_type` | `string` | **yes** | The type of notice being represented. |
| `admin_contact` | `string` | no | A URI giving a contact method for the server administrator. Required if the
notice type is `m.server_notice.usage_limit_reached`. |
| `limit_type` | `string` | no | The kind of usage limit the server has exceeded. Required if the notice type is
`m.server_notice.usage_limit_reached`. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "Human-readable message to explain the notice",
    "msgtype": "m.server_notice",
    "server_notice_type": "m.server_notice.usage_limit_reached",
    "admin_contact": "mailto:server.admin@example.org",
    "limit_type": "monthly_active_user"
  }
}
```

</details>

##### `m.text`

This message is the most basic message and is used to represent text.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | The body of the message. |
| `msgtype` | `string` | **yes** |  One of: `m.text`. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`. This is required if `format`
is specified. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "This is an example text message",
    "msgtype": "m.text",
    "format": "org.matrix.custom.html",
    "formatted_body": "<b>This is an example text message</b>"
  }
}
```

</details>

##### `m.video`

This message represents a single video clip.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | If `filename` is not set or the value of both properties are
identical, this is the filename of the original upload. Otherwise,
this is a caption for the video. |
| `format` | `string` | no | The format used in the `formatted_body`. This is required if `formatted_body`
is specified. Currently only `org.matrix.custom.html` is supported. |
| `formatted_body` | `string` | no | The formatted version of the `body`, when it acts as a caption. This
is required if `format` is specified. |
| `filename` | `string` | no | The original filename of the uploaded file. |
| `info` | `object` | no | Metadata about the video clip referred to in `url`. Contains: `duration` (integer): The duration of the video in milliseconds.; `h` (integer): The height of the video in pixels.; `w` (integer): The width of the video in pixels.; `mimetype` (string): The mimetype of the video e.g. `video/mp4`.; `size` (integer): The size of the video in bytes.; `thumbnail_url` (string): The URL (typically [`mxc://` URI](/client-server-api/#matrix-content-mxc-uris)) to an image thumbnail of
the video clip. Only present if the thumbnail is unencrypted.; `thumbnail_file` (object): Information on the encrypted thumbnail file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments).
Only present if the thumbnail is encrypted.; `thumbnail_info` (object): Metadata about the image referred to in `thumbnail_url`.. |
| `msgtype` | `string` | **yes** |  One of: `m.video`. |
| `url` | `string` | no | Required if the file is unencrypted. The URL (typically [`mxc://` URI](/client-server-api/#matrix-content-mxc-uris))
to the video clip. |
| `file` | `object` | no | Required if the file is encrypted. Information on the encrypted
file, as specified in
[End-to-end encryption](/client-server-api/#sending-encrypted-attachments). |

<details><summary>Example</summary>

```json
{
  "type": "m.room.message",
  "content": {
    "body": "Gangnam Style",
    "url": "mxc://example.org/a526eYUSFFxlgbQYZmo442",
    "info": {
      "thumbnail_url": "mxc://example.org/FHyPlCeYUSFFxlgbQYZmoEoe",
      "thumbnail_info": {
        "mimetype": "image/jpeg",
        "size": 46144,
        "w": 300,
        "h": 300
      },
      "w": 480,
      "h": 320,
      "duration": 2140786,
      "size": 1563685,
      "mimetype": "video/mp4"
    },
    "msgtype": "m.video"
  }
}
```

</details>

---


### `m.room.redaction`

This event is created by the server to describe which event has been redacted, by whom, and optionally why. The event that has been redacted is specified in the `redacts` event level key. Redacting an event means that all keys not required by the protocol are stripped off, allowing messages to be hidden or allowing admins to remove offensive or illegal content.

- **Kind:** Room message event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `redacts` | `string` | no | The event ID that was redacted. Required for, and present starting in, room version 11. |
| `reason` | `string` | no | The reason for the redaction, if any. |

<details><summary>Example</summary>

```json
{
  "type": "m.room.redaction",
  "content": {
    "redacts": "$fukweghifu23:localhost",
    "reason": "Spamming"
  }
}
```

</details>

---


### `m.sticker`

This message represents a single sticker image.

- **Kind:** Room message event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `string` | **yes** | A textual representation or associated description of the sticker
image. This could be the alt text of the original image, or a message
to accompany and further describe the sticker. |
| `info` | `object` | **yes** | Metadata about the image referred to in `url` including a thumbnail
representation. |
| `url` | `string` | **yes** | The URL to the sticker image. This must be a valid `mxc://` URI. |

<details><summary>Example</summary>

```json
{
  "type": "m.sticker",
  "content": {
    "body": "Landing",
    "info": {
      "mimetype": "image/png",
      "thumbnail_info": {
        "mimetype": "image/png",
        "h": 200,
        "w": 140,
        "size": 73602,
        "is_animated": true
      },
      "h": 200,
      "thumbnail_url": "mxc://matrix.org/sHhqkFCvSkFwtmvtETOtKnLP",
      "w": 140,
      "size": 73602
    },
    "url": "mxc://matrix.org/sHhqkFCvSkFwtmvtETOtKnLP"
  }
}
```

</details>

---


## Ephemeral Events


### `m.presence`

Informs the client of a user's presence state change.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `avatar_url` | `string` | no | The current avatar URL for this user, if any. |
| `displayname` | `string` | no | The current display name for this user, if any. |
| `last_active_ago` | `number` | no | The last time since this used performed some action, in milliseconds. |
| `presence` | `string` | **yes** | The presence state for this user. One of: `online`, `offline`, `unavailable`. |
| `currently_active` | `boolean` | no | Whether the user is currently active |
| `status_msg` | `string` | no | An optional description to accompany the presence. |

<details><summary>Example</summary>

```json
{
  "sender": "@example:localhost",
  "type": "m.presence",
  "content": {
    "avatar_url": "mxc://localhost/wefuiwegh8742w",
    "last_active_ago": 2478593,
    "presence": "online",
    "currently_active": false,
    "status_msg": "Making cupcakes"
  }
}
```

</details>

---


### `m.receipt`

Informs the client of new receipts.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `(pattern keys)` | `object` | no | The mapping of event ID to a collection of receipts for this
event ID. The event ID is the ID of the event being acknowledged
and *not* an ID for the receipt itself. |

<details><summary>Example</summary>

```json
{
  "type": "m.receipt",
  "content": {
    "$1435641916114394fHBLK:matrix.org": {
      "m.read": {
        "@erikj:jki.re": {
          "ts": 1436451550453
        }
      },
      "m.read.private": {
        "@self:example.org": {
          "ts": 1661384801651
        }
      }
    }
  }
}
```

</details>

---


### `m.typing`

Informs the client of the list of users currently typing.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `user_ids` | `array` | **yes** | The list of user IDs typing in this room, if any. |

<details><summary>Example</summary>

```json
{
  "type": "m.typing",
  "content": {
    "user_ids": [
      "@alice:matrix.org",
      "@bob:example.com"
    ]
  }
}
```

</details>

---


## Space Events


### `m.space.child`

Defines the relationship of a child room to a space-room. Has no effect in rooms which are not [spaces](/client-server-api/#spaces).

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `via` | `array` | **yes** | A list of servers to try and join through. See also: [Routing](/appendices/#routing). When not present or invalid, the child room is not considered to be part of the space. |
| `order` | `string` | no | Optional string to define ordering among space children. These are lexicographically
compared against other children's `order`, if present. Must consist of ASCII characters within the range `\x20` (space) and `\x7E` (`~`),
inclusive. Must not exceed 50 characters. `order` values with the wrong type, or otherwise invalid contents, are to be treated
as though the `order` key was not provided. See [Ordering of children within a space](/client-server-api/#ordering-of-children-within-a-space) for information on how the ordering works. |
| `suggested` | `boolean` | no | Optional (default `false`) flag to denote whether the child is "suggested" or of interest
to members of the space. This is primarily intended as a rendering hint for clients to
display the room differently, such as eagerly rendering them in the room list. |

<details><summary>Example</summary>

```json
{
  "type": "m.space.child",
  "state_key": "!roomid:example.org",
  "content": {
    "suggested": true,
    "via": [
      "example.org",
      "other.example.org"
    ],
    "order": "lexicographically_compare_me"
  }
}
```

</details>

---


### `m.space.parent`

Defines the relationship of a room to a parent space-room.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `via` | `array` | **yes** | A list of servers to try and join through. See also: [Routing](/appendices/#routing). When not present or invalid, the room is not considered to be part of the parent space. |
| `canonical` | `boolean` | no | Optional (default `false`) flag to denote this parent is the primary parent for the room. When multiple `canonical` parents are found, the lowest parent when ordering by room ID
lexicographically by Unicode code-points should be used. |

<details><summary>Example</summary>

```json
{
  "type": "m.space.parent",
  "state_key": "!parent_roomid:example.org",
  "content": {
    "canonical": true,
    "via": [
      "example.org",
      "other.example.org"
    ]
  }
}
```

</details>

---


## VoIP Events


### `m.call.answer`

This event is sent by the callee when they wish to answer the call.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `answer` | `object` | **yes** | The session description object Contains: `type` (string): The type of session description.; `sdp` (string): The SDP text of the session description.. |
| `sdp_stream_metadata` | `object` | no |  |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.answer",
  "content": {
    "version": "1",
    "party_id": "67890",
    "call_id": "12345",
    "answer": {
      "type": "answer",
      "sdp": "v=0\r\no=- 6584580628695956864 2 IN IP4 127.0.0.1[...]"
    },
    "sdp_stream_metadata": {
      "271828182845": {
        "purpose": "m.screenshare"
      },
      "314159265358": {
        "purpose": "m.usermedia"
      }
    }
  }
}
```

</details>

---


### `m.call.candidates`

This event is sent by callers after sending an invite and by the callee after
answering. Its purpose is to give the other party additional ICE candidates to
try using to communicate.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `candidates` | `array` | **yes** | Array of objects describing the candidates. |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.candidates",
  "content": {
    "version": "1",
    "party_id": "67890",
    "call_id": "12345",
    "candidates": [
      {
        "sdpMid": "audio",
        "sdpMLineIndex": 0,
        "candidate": "candidate:863018703 1 udp 2122260223 10.9.64.156 43670 typ host generation 0"
      }
    ]
  }
}
```

</details>

---


### `m.call.hangup`

Sent by either party to signal their termination of the call. This can
be sent either once the call has has been established or before to abort the call.

The meanings of the `reason` field are as follows:
 * `ice_failed`: ICE negotiation has failed and a media connection could not be established.
 * `ice_timeout`: The connection failed after some media was exchanged (as opposed to `ice_failed`
    which means no media connection could be established). Note that, in the case of an ICE
    renegotiation, a client should be sure to send `ice_timeout` rather than `ice_failed` if media
    had previously been received successfully, even if the ICE renegotiation itself failed.
 * `invite_timeout`: The other party did not answer in time.
 * `user_hangup`: Clients must now send this code when the user chooses to end the call, although
   for backwards compatibility with version 0, a clients should treat an absence of the `reason`
   field as `user_hangup`.
 * `user_media_failed`: The client was unable to start capturing media in such a way that it is unable
   to continue the call.
 * `user_busy`: The user is busy. Note that this exists primarily for bridging to other networks such
    as the PSTN. A Matrix client that receives a call whilst already in a call would not generally reject
    the new call unless the user had specifically chosen to do so.
 * `unknown_error`: Some other failure occurred that meant the client was unable to continue the call
    rather than the user choosing to end it.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `reason` | `string` | **yes** | Reason for the hangup. Note that this was optional in previous previous versions of the spec, so a missing value should be treated as `user_hangup`. One of: `ice_timeout`, `ice_failed`, `invite_timeout`, `user_hangup`, `user_media_failed`, `user_busy`, `unknown_error`. |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.hangup",
  "content": {
    "version": "1",
    "party_id": "67890",
    "call_id": "12345",
    "reason": "user_hangup"
  }
}
```

</details>

---


### `m.call.invite`

This event is sent by the caller when they wish to establish a call.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `offer` | `object` | **yes** | The session description object Contains: `type` (string): The type of session description.; `sdp` (string): The SDP text of the session description.. |
| `lifetime` | `integer` | **yes** | The time in milliseconds that the invite is valid for. Once the invite age exceeds this value, clients should discard it. They should also no longer show the call as awaiting an answer in the UI. |
| `invitee` | `string` | no | The ID of the user being called. If omitted, any user in the room can answer. |
| `sdp_stream_metadata` | `object` | no |  |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.invite",
  "content": {
    "version": "1",
    "party_id": "67890",
    "call_id": "12345",
    "lifetime": 60000,
    "offer": {
      "type": "offer",
      "sdp": "v=0\r\no=- 6584580628695956864 2 IN IP4 127.0.0.1[...]"
    },
    "sdp_stream_metadata": {
      "271828182845": {
        "purpose": "m.screenshare"
      },
      "314159265358": {
        "purpose": "m.usermedia"
      }
    }
  }
}
```

</details>

---


### `m.call.negotiate`

Provides SDP negotiation semantics for media pause, hold/resume, ICE restarts
and voice/video call up/downgrading. Clients should implement and honour hold
functionality as per [WebRTC's recommendation](https://www.w3.org/TR/webrtc/#hold-functionality).

If both the invite event and the accepted answer event have `version` equal
to `"1"`, either party may send `m.call.negotiate` with a `description` field
to offer new SDP to the other party. This event has `call_id` with the ID of
the call and `party_id` equal to the client's party ID for that call.  The
caller ignores any negotiate events with `party_id` + `user_id` tuple not
equal to that of the answer it accepted and the callee ignores any negotiate
events with `party_id` + `user_id` tuple not equal to that of the caller.
Clients should use the `party_id` field to ignore the remote echo of their
own negotiate events.

This has a `lifetime` field as in `m.call.invite`, after which the sender of
the negotiate event should consider the negotiation failed (timed out) and
the recipient should ignore it.

The `description` field is the same as the `offer` field in `m.call.invite`
and `answer` field in `m.call.answer` and is an `RTCSessionDescriptionInit`
object as per https://www.w3.org/TR/webrtc/#dom-rtcsessiondescriptioninit.

Once an `m.call.negotiate` event is received, the client must respond with
another `m.call.negotiate` event, with the SDP answer (with `"type": "answer"`)
in the `description` property.

In the `m.call.invite` and `m.call.answer` events, the `offer` and `answer`
fields respectively are objects of type `RTCSessionDescriptionInit`.  Hence
the `type` field, whilst redundant in these events, is included for ease of
working with the WebRTC API and is mandatory. Receiving clients should not
attempt to validate the `type` field, but simply pass the object into the
WebRTC API.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `description` | `object` | **yes** | The session description object Contains: `type` (string): The type of session description.; `sdp` (string): The SDP text of the session description.. |
| `lifetime` | `integer` | **yes** | The time in milliseconds that the negotiation is valid for. Once the negotiation age exceeds this value, clients should discard it. |
| `sdp_stream_metadata` | `object` | no |  |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.negotiate",
  "content": {
    "version": "1",
    "party_id": "67890",
    "call_id": "12345",
    "lifetime": 10000,
    "description": {
      "type": "offer",
      "sdp": "v=0\r\no=- 6584580628695956864 2 IN IP4 127.0.0.1[...]"
    },
    "sdp_stream_metadata": {
      "271828182845": {
        "purpose": "m.screenshare"
      },
      "314159265358": {
        "purpose": "m.usermedia"
      }
    }
  }
}
```

</details>

---


### `m.call.reject`

If the `m.call.invite` event has `version` `"1"`, a client wishing to
reject the call sends an `m.call.reject` event. This rejects the call on all devices,
but if the calling device sees an `answer` before the `reject`, it disregards the
reject event and carries on. The reject has a `party_id` just like an answer, and
the caller sends a `select_answer` for it just like an answer. If another client
had already sent an answer and sees the caller select the reject response instead
of its answer, it ends the call. If the `m.call.invite` event has `version` `0`,
the callee sends an `m.call.hangup` event. If the calling user chooses to end the
call before setup is complete, the client sends `m.call.hangup` as previously.

Note that, unlike `m.call.hangup`, this event has no `reason` field: the rejection of
a call is always implicitly because the user chose not to answer it.

- **Kind:** Room message event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.reject",
  "content": {
    "version": "1",
    "party_id": "67890",
    "call_id": "12345"
  }
}
```

</details>

---


### `m.call.sdp_stream_metadata_changed`

This event is sent by callers when they wish to update a stream's metadata
but no negotiation is required.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `sdp_stream_metadata` | `object` | **yes** |  |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.sdp_stream_metadata_changed",
  "content": {
    "version": "1",
    "call_id": "1414213562373095",
    "party_id": "1732050807568877",
    "sdp_stream_metadata": {
      "2311546231": {
        "purpose": "m.usermedia",
        "audio_muted:": true,
        "video_muted": true
      }
    }
  }
}
```

</details>

---


### `m.call.select_answer`

This event is sent by the caller's client once it has decided which other client to talk to, by selecting one of multiple possible incoming `m.call.answer` events. Its `selected_party_id` field indicates the answer it's chosen. The `call_id` and `party_id` of the caller is also included. If the callee's client sees a `select_answer` for an answer with party ID other than the one it sent, it ends the call and informs the user the call was answered elsewhere. It does not send any events. Media can start flowing before this event is seen or even sent.  Clients that implement previous versions of this specification will ignore this event and behave as they did before.

- **Kind:** Room message event (VoIP)


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `selected_party_id` | `string` | **yes** | The `party_id` field from the answer event that the caller chose. |
| `call_id` | `string` | **yes** | The ID of the call this event relates to. |
| `version` | `string` | **yes** | The version of the VoIP specification this message adheres to. This specification is version 1. This field is a string such that experimental implementations can use non-integer versions. This field was an integer in the previous spec version and implementations must accept an integer 0. |
| `party_id` | `string` | **yes** | This identifies the party that sent this event. A client may choose to re-use the device ID from end-to-end cryptography for the value of this field. |

<details><summary>Example</summary>

```json
{
  "type": "m.call.select_answer",
  "content": {
    "version": "1",
    "call_id": "12345",
    "party_id": "67890",
    "selected_party_id": "111213"
  }
}
```

</details>

---


## Moderation Policy Events


### `m.policy.rule.room`

A moderation policy rule which affects room IDs and room aliases.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `entity` | `string` | **yes** | The entity affected by this rule. Glob characters `*` and `?` can be used
to match zero or more characters or exactly one character respectively. |
| `recommendation` | `string` | **yes** | The suggested action to take. Currently only `m.ban` is specified. |
| `reason` | `string` | **yes** | The human-readable description for the `recommendation`. |

<details><summary>Example</summary>

```json
{
  "type": "m.policy.rule.room",
  "state_key": "rule:#*:example.org",
  "content": {
    "entity": "#*:example.org",
    "recommendation": "m.ban",
    "reason": "undesirable content"
  }
}
```

</details>

---


### `m.policy.rule.server`

A moderation policy rule which affects servers.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `entity` | `string` | **yes** | The entity affected by this rule. Glob characters `*` and `?` can be used
to match zero or more characters or exactly one character respectively. |
| `recommendation` | `string` | **yes** | The suggested action to take. Currently only `m.ban` is specified. |
| `reason` | `string` | **yes** | The human-readable description for the `recommendation`. |

<details><summary>Example</summary>

```json
{
  "type": "m.policy.rule.server",
  "state_key": "rule:*.example.org",
  "content": {
    "entity": "*.example.org",
    "recommendation": "m.ban",
    "reason": "undesirable engagement"
  }
}
```

</details>

---


### `m.policy.rule.user`

A moderation policy rule which affects users.

- **Kind:** State event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `entity` | `string` | **yes** | The entity affected by this rule. Glob characters `*` and `?` can be used
to match zero or more characters or exactly one character respectively. |
| `recommendation` | `string` | **yes** | The suggested action to take. Currently only `m.ban` is specified. |
| `reason` | `string` | **yes** | The human-readable description for the `recommendation`. |

<details><summary>Example</summary>

```json
{
  "type": "m.policy.rule.user",
  "state_key": "rule:@alice*:example.org",
  "content": {
    "entity": "@alice*:example.org",
    "recommendation": "m.ban",
    "reason": "undesirable behaviour"
  }
}
```

</details>

---


## Account Data & Other Events


### `m.accepted_terms`

A list of terms URLs the user has previously accepted. Clients SHOULD use this
to avoid presenting the user with terms they have already agreed to.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `accepted` | `array` | no | The list of URLs the user has previously accepted. Should be appended to
when the user agrees to new terms. |

<details><summary>Example</summary>

```json
{
  "type": "m.accepted_terms",
  "content": {
    "accepted": [
      "https://example.org/somewhere/terms-1.2-en.html",
      "https://example.org/somewhere/privacy-1.2-en.html"
    ]
  }
}
```

</details>

---


### `m.direct`

A map of which rooms are considered 'direct' rooms for specific users
is kept in  `account_data` in an event of type `m.direct`. The
content of this event is an object where the keys are the user IDs
and values are lists of room ID strings of the 'direct' rooms for
that user ID.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `(pattern keys)` | `object` | no | The mapping of user ID to a list of room IDs of the 'direct' rooms for
that user ID. |

<details><summary>Example</summary>

```json
{
  "type": "m.direct",
  "content": {
    "@bob:example.com": [
      "!abcdefgh:example.com",
      "!hgfedcba:example.com"
    ]
  }
}
```

</details>

---


### `m.fully_read`

The current location of the user's read marker in a room. This event appears in the user's room account data for the room the marker is applicable for.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `event_id` | `string` | **yes** | The event the user's read marker is located at in the room. |

<details><summary>Example</summary>

```json
{
  "type": "m.fully_read",
  "content": {
    "event_id": "$someplace:example.org"
  }
}
```

</details>

---


### `m.identity_server`

Persists the user's preferred identity server, or preference to not use
an identity server at all, in the user's account data.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `base_url` | `object` | no | The URL of the identity server the user prefers to use, or `null`
if the user does not want to use an identity server. This value is
similar in structure to the `base_url` for identity servers in the
`.well-known/matrix/client` schema. |

<details><summary>Example</summary>

```json
{
  "type": "m.identity_server",
  "content": {
    "base_url": "https://example.org"
  }
}
```

</details>

---


### `m.ignored_user_list`

A map of users which are considered ignored is kept in `account_data`
in an event type of `m.ignored_user_list`.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `ignored_users` | `object` | **yes** | The map of users to ignore. This is a mapping of user ID to empty
object. |

<details><summary>Example</summary>

```json
{
  "type": "m.ignored_user_list",
  "content": {
    "ignored_users": {
      "@someone:example.org": {}
    }
  }
}
```

</details>

---


### `m.invite_permission_config`



- **Kind:** Basic event

<details><summary>Example</summary>

```json
{
  "type": "m.invite_permission_config",
  "content": {
    "default_action": "block"
  }
}
```

</details>

---


### `m.marked_unread`

The current state of the user's unread marker in a room. This event appears in the user's room account data for the room the marker is applicable for.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `unread` | `boolean` | **yes** | Whether the room is marked unread or not. |

<details><summary>Example</summary>

```json
{
  "type": "m.marked_unread",
  "content": {
    "unread": true
  }
}
```

</details>

---


### `m.push_rules`

Describes all push rules for this user.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `global` | `object` | no | The global ruleset |

<details><summary>Example</summary>

```json
{
  "type": "m.push_rules",
  "content": {
    "global": {
      "override": [
        {
          "actions": [],
          "conditions": [],
          "default": true,
          "enabled": false,
          "rule_id": ".m.rule.master"
        },
        {
          "actions": [],
          "conditions": [
            {
              "key": "content.msgtype",
              "kind": "event_match",
              "pattern": "m.notice"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.suppress_notices"
        }
      ],
      "room": [],
      "sender": [],
      "underride": [
        {
          "actions": [
            "notify",
            {
              "set_tweak": "sound",
              "value": "ring"
            },
            {
              "set_tweak": "highlight",
              "value": false
            }
          ],
          "conditions": [
            {
              "key": "type",
              "kind": "event_match",
              "pattern": "m.call.invite"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.call"
        },
        {
          "actions": [
            "notify",
            {
              "set_tweak": "sound",
              "value": "default"
            },
            {
              "set_tweak": "highlight"
            }
          ],
          "conditions": [
            {
              "kind": "event_property_contains",
              "key": "content.m\\.mentions.user_ids",
              "value": "@alice:example.com"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.is_user_mention"
        },
        {
          "actions": [
            "notify",
            {
              "set_tweak": "sound",
              "value": "default"
            },
            {
              "set_tweak": "highlight",
              "value": false
            }
          ],
          "conditions": [
            {
              "kind": "room_member_count",
              "is": "2"
            },
            {
              "kind": "event_match",
              "key": "type",
              "pattern": "m.room.message"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.room_one_to_one"
        },
        {
          "actions": [
            "notify",
            {
              "set_tweak": "sound",
              "value": "default"
            },
            {
              "set_tweak": "highlight",
              "value": false
            }
          ],
          "conditions": [
            {
              "key": "type",
              "kind": "event_match",
              "pattern": "m.room.member"
            },
            {
              "key": "content.membership",
              "kind": "event_match",
              "pattern": "invite"
            },
            {
              "key": "state_key",
              "kind": "event_match",
              "pattern": "@alice:example.com"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.invite_for_me"
        },
        {
          "actions": [
            "notify",
            {
              "set_tweak": "highlight",
              "value": false
            }
          ],
          "conditions": [
            {
              "key": "type",
              "kind": "event_match",
              "pattern": "m.room.member"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.member_event"
        },
        {
          "actions": [
            "notify",
            {
              "set_tweak": "highlight",
              "value": false
            }
          ],
          "conditions": [
            {
              "key": "type",
              "kind": "event_match",
              "pattern": "m.room.message"
            }
          ],
          "default": true,
          "enabled": true,
          "rule_id": ".m.rule.message"
        }
      ]
    }
  }
}
```

</details>

---


### `m.recent_emoji`

Lets clients maintain a list of recently used emoji.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `recent_emoji` | `array` | **yes** | The list of recently used emoji. Elements in the list are ordered descendingly by last usage time. |

<details><summary>Example</summary>

```json
{
  "type": "m.recent_emoji",
  "content": {
    "recent_emoji": [
      {
        "emoji": "🤔",
        "total": 19
      },
      {
        "emoji": "👍",
        "total": 7
      },
      {
        "emoji": "😅",
        "total": 84
      }
    ]
  }
}
```

</details>

---


### `m.room.encrypted`

This event type is used when sending encrypted events. It can be used either
within a room (in which case it will have all of the normal properties in
[Room events](/client-server-api/#room-event-format)), or
as a [to-device](/client-server-api/#send-to-device-messaging) event.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `algorithm` | `string` | **yes** | The encryption algorithm used to encrypt this event. The
value of this field determines which other properties will be
present. One of: `m.olm.v1.curve25519-aes-sha2`, `m.megolm.v1.aes-sha2`. |
| `ciphertext` | `object` | **yes** | The encrypted content of the event. Either the encrypted payload
itself, in the case of a Megolm event, or a map from the recipient
Curve25519 identity key to ciphertext information, in the case of an
Olm event. For more details, see [Messaging Algorithms](/client-server-api/#messaging-algorithms). |
| `sender_key` | `string` | no | The Curve25519 key of the sender. Required (not deprecated) if not using Megolm. **Deprecated**: This field provides no additional security or privacy benefit
for Megolm messages and must not be read from if the encrypted event is using
Megolm. It should still be included on outgoing messages, however must not be
used to find the corresponding session. See [`m.megolm.v1.aes-sha2`](/client-server-api/#mmegolmv1aes-sha2)
for more information. |
| `device_id` | `string` | no | The ID of the sending device. **Deprecated**: This field provides no additional security or privacy benefit
for Megolm messages and must not be read from if the encrypted event is using
Megolm. It should still be included on outgoing messages, however must not be
used to find the corresponding session. See [`m.megolm.v1.aes-sha2`](/client-server-api/#mmegolmv1aes-sha2)
for more information. |
| `session_id` | `string` | no | The ID of the session used to encrypt the message. Required with
Megolm. |

---


### `m.tag`

Informs the client of tags on a room.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `tags` | `object` | no | The tags on the room and their contents. |

<details><summary>Example</summary>

```json
{
  "type": "m.tag",
  "content": {
    "tags": {
      "u.work": {
        "order": 0.9
      }
    }
  }
}
```

</details>

---


## Key Verification Events


### `m.key.verification.accept`

Accepts a previously sent `m.key.verification.start` message.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification process. Must be the same as the one used for the
`m.key.verification.start` message. |
| `key_agreement_protocol` | `string` | **yes** | The key agreement protocol the device is choosing to use, out of the
options in the `m.key.verification.start` message. |
| `hash` | `string` | **yes** | The hash method the device is choosing to use, out of the options in
the `m.key.verification.start` message. |
| `message_authentication_code` | `string` | **yes** | The message authentication code method the device is choosing to use, out of
the options in the `m.key.verification.start` message. |
| `short_authentication_string` | `array` | **yes** | The SAS methods both devices involved in the verification process
understand. Must be a subset of the options in the `m.key.verification.start`
message. |
| `commitment` | `string` | **yes** | The hash (encoded as unpadded base64) of the concatenation of the device's
ephemeral public key (encoded as unpadded base64) and the canonical JSON
representation of the `content` object of the `m.key.verification.start`
message. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.accept",
  "content": {
    "transaction_id": "S0meUniqueAndOpaqueString",
    "method": "m.sas.v1",
    "key_agreement_protocol": "curve25519",
    "hash": "sha256",
    "message_authentication_code": "hkdf-hmac-sha256.v2",
    "short_authentication_string": [
      "decimal",
      "emoji"
    ],
    "commitment": "fQpGIW1Snz+pwLZu6sTy2aHy/DYWWTspTJRPyNp0PKkymfIsNffysMl6ObMMFdIJhk6g6pwlIqZ54rxo8SLmAg"
  }
}
```

</details>

---


### `m.key.verification.cancel`

Cancels a key verification process/request.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `transaction_id` | `string` | no | Required when sent as a to-device message. The opaque identifier for
the verification process/request. |
| `reason` | `string` | **yes** | A human readable description of the `code`. The client should only rely on this
string if it does not understand the `code`. |
| `code` | `string` | **yes** | The error code for why the process/request was cancelled by the user. Error
codes should use the Java package naming convention if not in the following
list: * `m.user`: The user cancelled the verification. * `m.timeout`: The verification process timed out. Verification processes
can define their own timeout parameters. * `m.unknown_transaction`: The device does not know about the given transaction
ID. * `m.unknown_method`: The device does not know how to handle the requested
method. This should be sent for `m.key.verification.start` messages and
messages defined by individual verification processes. * `m.unexpected_message`: The device received an unexpected message. Typically
raised when one of the parties is handling the verification out of order. * `m.key_mismatch`: The key was not verified. * `m.user_mismatch`: The expected user did not match the user verified. * `m.invalid_message`: The message received was invalid. * `m.accepted`: A `m.key.verification.request` was accepted by a different device. The device receiving this error can ignore the verification request. Clients should be careful to avoid error loops. For example, if a device sends
an incorrect message and the client returns `m.invalid_message` to which it
gets an unexpected response with `m.unexpected_message`, the client should not
respond again with `m.unexpected_message` to avoid the other device potentially
sending another error response. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.cancel",
  "content": {
    "transaction_id": "S0meUniqueAndOpaqueString",
    "code": "m.user",
    "reason": "User rejected the key verification request"
  }
}
```

</details>

---


### `m.key.verification.done`

Indicates that a verification process/request has completed successfully.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `transaction_id` | `string` | no | Required when sent as a to-device message. The opaque identifier for
the verification process/request. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.done",
  "content": {
    "transaction_id": "S0meUniqueAndOpaqueString"
  }
}
```

</details>

---


### `m.key.verification.key`

Sends the ephemeral public key for a device to the partner device.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification process. Must be the same as the one used for the
`m.key.verification.start` message. |
| `key` | `string` | **yes** | The device's ephemeral public key, encoded as unpadded base64. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.key",
  "content": {
    "transaction_id": "S0meUniqueAndOpaqueString",
    "key": "fQpGIW1Snz+pwLZu6sTy2aHy/DYWWTspTJRPyNp0PKkymfIsNffysMl6ObMMFdIJhk6g6pwlIqZ54rxo8SLmAg"
  }
}
```

</details>

---


### `m.key.verification.m.relates_to`

Required when sent as an in-room message. Indicates the
`m.key.verification.request` that this message is related to. Note that for
encrypted messages, this property should be in the unencrypted portion of the
event.

- **Kind:** Basic event

---


### `m.key.verification.mac`

Sends the MAC of a device's key to the partner device.  The MAC is calculated
using the method given in `message_authentication_code` property of the
`m.key.verification.accept` message.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification process. Must be the same as the one used for the
`m.key.verification.start` message. |
| `mac` | `object` | **yes** | A map of the key ID to the MAC of the key, using the algorithm in the
verification process. The MAC is encoded as unpadded base64. |
| `keys` | `string` | **yes** | The MAC of the comma-separated, sorted, list of key IDs given in the `mac`
property, encoded as unpadded base64. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.mac",
  "content": {
    "transaction_id": "S0meUniqueAndOpaqueString",
    "keys": "2Wptgo4CwmLo/Y8B8qinxApKaCkBG2fjTWB7AbP5Uy+aIbygsSdLOFzvdDjww8zUVKCmI02eP9xtyJxc/cLiBA",
    "mac": {
      "ed25519:ABCDEF": "fQpGIW1Snz+pwLZu6sTy2aHy/DYWWTspTJRPyNp0PKkymfIsNffysMl6ObMMFdIJhk6g6pwlIqZ54rxo8SLmAg"
    }
  }
}
```

</details>

---


### `m.key.verification.ready`

Accepts a key verification request. Sent in response to an
`m.key.verification.request` event.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `from_device` | `string` | **yes** | The device ID which is accepting the request. |
| `transaction_id` | `string` | no | Required when sent as a to-device message. The transaction ID of the
verification request, as given in the `m.key.verification.request`
message. |
| `methods` | `array` | **yes** | The verification methods supported by the sender, corresponding to
the verification methods indicated in the
`m.key.verification.request` message. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.ready",
  "content": {
    "from_device": "BobDevice1",
    "transaction_id": "S0meUniqueAndOpaqueString",
    "methods": [
      "m.sas.v1"
    ]
  }
}
```

</details>

---


### `m.key.verification.request`

Requests a key verification using to-device messaging.  When requesting a key
verification in a room, a `m.room.message` should be used, with
[`m.key.verification.request`](/client-server-api/#mroommessagemkeyverificationrequest)
as msgtype.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `from_device` | `string` | **yes** | The device ID which is initiating the request. |
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification request. Must be unique with respect to the devices
involved. |
| `methods` | `array` | **yes** | The verification methods supported by the sender. |
| `timestamp` | `integer` | no | Required when sent as a to-device message. The POSIX timestamp in
milliseconds for when the request was made. If the request is in the
future by more than 5 minutes or more than 10 minutes in the past,
the message should be ignored by the receiver. |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.request",
  "content": {
    "from_device": "AliceDevice2",
    "transaction_id": "S0meUniqueAndOpaqueString",
    "methods": [
      "m.sas.v1"
    ],
    "timestamp": 1559598944869
  }
}
```

</details>

---


### `m.key.verification.start`

Begins a key verification process. Typically sent as a [to-device](/client-server-api/#send-to-device-messaging) event. The `method`
field determines the type of verification. The fields in the event will differ depending
on the `method`. This definition includes fields that are in common among all variants.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `from_device` | `string` | **yes** | The device ID which is initiating the process. |
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification process. Must be unique with respect to the devices
involved. Must be the same as the `transaction_id` given in the
`m.key.verification.request` if this process is originating from a
request. |
| `method` | `string` | **yes** | The verification method to use. |
| `next_method` | `string` | no | Optional method to use to verify the other user's key with. Applicable
when the `method` chosen only verifies one user's key. This field will
never be present if the `method` verifies keys both ways. |
| `m.relates_to` | `object` | no |  |

#### Message Types (`content.msgtype`)

##### `m.reciprocate.v1`

Begins a key verification process using the `m.reciprocate.v1` method, after
scanning a QR code.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `from_device` | `string` | **yes** | The device ID which is initiating the process. |
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification process. Must be unique with respect to the devices
involved. Must be the same as the `transaction_id` given in the
`m.key.verification.request` if this process is originating from a
request. |
| `method` | `string` | **yes** | The verification method to use. One of: `m.reciprocate.v1`. |
| `secret` | `string` | **yes** | The shared secret from the QR code, encoded using unpadded base64. |
| `m.relates_to` | `object` | no |  |

##### `m.sas.v1`

Begins a SAS key verification process using the `m.sas.v1` method.


| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `from_device` | `string` | **yes** | The device ID which is initiating the process. |
| `transaction_id` | `string` | no | Required when sent as a to-device message. An opaque identifier for
the verification process. Must be unique with respect to the devices
involved. Must be the same as the `transaction_id` given in the
`m.key.verification.request` if this process is originating from a
request. |
| `method` | `string` | **yes** | The verification method to use. One of: `m.sas.v1`. |
| `key_agreement_protocols` | `array` | **yes** | The key agreement protocols the sending device understands. Should
include at least `curve25519-hkdf-sha256`. |
| `hashes` | `array` | **yes** | The hash methods the sending device understands. Must include at least
`sha256`. |
| `message_authentication_codes` | `array` | **yes** | The message authentication code methods that the sending device understands.
Must include at least `hkdf-hmac-sha256.v2`.  Should also include
`hkdf-hmac-sha256` for compatibility with older clients, though this
identifier is deprecated and will be removed in a future version of
the spec. |
| `short_authentication_string` | `array` | **yes** | The SAS methods the sending device (and the sending device's user)
understands. Must include at least `decimal`. Optionally can include
`emoji`. |
| `m.relates_to` | `object` | no |  |

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.start",
  "content": {
    "from_device": "BobDevice1",
    "transaction_id": "S0meUniqueAndOpaqueString",
    "method": "m.sas.v1",
    "key_agreement_protocols": [
      "curve25519"
    ],
    "hashes": [
      "sha256"
    ],
    "message_authentication_codes": [
      "hkdf-hmac-sha256.v2",
      "hkdf-hmac-sha256"
    ],
    "short_authentication_string": [
      "decimal",
      "emoji"
    ]
  }
}
```

</details>

<details><summary>Example</summary>

```json
{
  "type": "m.key.verification.start",
  "content": {
    "from_device": "BobDevice1",
    "transaction_id": "S0meUniqueAndOpaqueString",
    "method": "m.sas.v1"
  }
}
```

</details>

---


## E2E & Key Management Events


### `m.dummy`

This event type is used to indicate new Olm sessions for end-to-end encryption.
Typically it is encrypted as an `m.room.encrypted` event, then sent as a [to-device](/client-server-api/#send-to-device-messaging)
event.

The event does not have any content associated with it. The sending client is expected
to send a key share request shortly after this message, causing the receiving client to
process this `m.dummy` event as the most recent event and using the keyshare request
to set up the session. The keyshare request and `m.dummy` combination should result
in the original sending client receiving keys over the newly established session.

- **Kind:** Basic event

<details><summary>Example</summary>

```json
{
  "content": {},
  "type": "m.dummy"
}
```

</details>

---


### `m.forwarded_room_key`

This event type is used to forward keys for end-to-end encryption.
It is encrypted as an `m.room.encrypted` event using [Olm](/client-server-api/#molmv1curve25519-aes-sha2),
then sent as a [to-device](/client-server-api/#send-to-device-messaging) event.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `algorithm` | `string` | **yes** | The encryption algorithm the key in this event is to be used with. |
| `room_id` | `string` | **yes** | The room where the key is used. |
| `sender_key` | `string` | **yes** | The Curve25519 key of the device which initiated the session originally. |
| `session_id` | `string` | **yes** | The ID of the session that the key is for. |
| `session_key` | `string` | **yes** | The key to be exchanged. |
| `sender_claimed_ed25519_key` | `string` | **yes** | The Ed25519 key of the device which initiated the session originally.
It is 'claimed' because the receiving device has no way to tell that the
original room_key actually came from a device which owns the private part of
this key unless they have done device verification. |
| `forwarding_curve25519_key_chain` | `array` | **yes** | Chain of Curve25519 keys. It starts out empty, but each time the
key is forwarded to another device, the previous sender in the chain is added
to the end of the list. For example, if the key is forwarded from A to B to
C, this field is empty between A and B, and contains A's Curve25519 key between
B and C. |
| `withheld` | `object` | no | Indicates that the key cannot be used to decrypt all the messages
from the session because a portion of the session was withheld as
described in [Reporting that decryption keys are withheld](/client-server-api/#reporting-that-decryption-keys-are-withheld). This
object must include the `code` and `reason` properties from the
`m.room_key.withheld` message that was received by the sender of
this message. |

<details><summary>Example</summary>

```json
{
  "content": {
    "algorithm": "m.megolm.v1.aes-sha2",
    "room_id": "!Cuyf34gef24t:localhost",
    "session_id": "X3lUlvLELLYxeTx4yOVu6UDpasGEVO0Jbu+QFnm0cKQ",
    "session_key": "AgAAAADxKHa9uFxcXzwYoNueL5Xqi69IkD4sni8Llf...",
    "sender_key": "RF3s+E7RkTQTGF2d8Deol0FkQvgII2aJDf3/Jp5mxVU",
    "sender_claimed_ed25519_key": "aj40p+aw64yPIdsxoog8jhPu9i7l7NcFRecuOQblE3Y",
    "forwarding_curve25519_key_chain": [
      "hPQNcabIABgGnx3/ACv/jmMmiQHoeFfuLB17tzWp6Hw"
    ]
  },
  "type": "m.forwarded_room_key"
}
```

</details>

---


### `m.key_backup`

Allows clients to track user preferences about key backup.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `enabled` | `boolean` | **yes** | True if the user chose to enable key backup. False if the user chose
to disable key backup. |

<details><summary>Example</summary>

```json
{
  "type": "m.key_backup",
  "content": {
    "enabled": false
  }
}
```

</details>

---


### `m.room_key`

This event type is used to exchange keys for end-to-end encryption.
It is encrypted as an `m.room.encrypted` event using [Olm](/client-server-api/#molmv1curve25519-aes-sha2),
then sent as a [to-device](/client-server-api/#send-to-device-messaging) event.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `algorithm` | `string` | **yes** | The encryption algorithm the key in this event is to be used with. One of: `m.megolm.v1.aes-sha2`. |
| `room_id` | `string` | **yes** | The room where the key is used. |
| `session_id` | `string` | **yes** | The ID of the session that the key is for. |
| `session_key` | `string` | **yes** | The key to be exchanged. |

<details><summary>Example</summary>

```json
{
  "type": "m.room_key",
  "content": {
    "algorithm": "m.megolm.v1.aes-sha2",
    "room_id": "!Cuyf34gef24t:localhost",
    "session_id": "X3lUlvLELLYxeTx4yOVu6UDpasGEVO0Jbu+QFnm0cKQ",
    "session_key": "AgAAAADxKHa9uFxcXzwYoNueL5Xqi69IkD4sni8LlfJL7qNBEY..."
  }
}
```

</details>

---


### `m.room_key.withheld`

This event type is used to indicate that the sender is not sharing room keys
with the recipient. It is sent as a to-device event.

Possible values for `code` include:

* `m.blacklisted`: the user/device was blacklisted.
* `m.unverified`: the user/device was not verified, and the sender is only
  sharing keys with verified users/devices.
* `m.unauthorised`: the user/device is not allowed to have the key. For
  example, this could be sent in response to a key request if the user/device
  was not in the room when the original message was sent.
* `m.unavailable`: sent in reply to a key request if the device that the
  key is requested from does not have the requested key.
* `m.no_olm`: an olm session could not be established.

In most cases, this event refers to a specific room key. The one exception to
this is when the sender is unable to establish an olm session with the
recipient. When this happens, multiple sessions will be affected.  In order
to avoid filling the recipient\'s device mailbox, the sender should only send
one `m.room_key.withheld` message with no `room_id` nor `session_id`
set.  If the sender retries and fails to create an olm session again in the
future, it should not send another `m.room_key.withheld` message with a
`code` of `m.no_olm`, unless another olm session was previously
established successfully.  In response to receiving an
`m.room_key.withheld` message with a `code` of `m.no_olm`, the
recipient may start an olm session with the sender and send an `m.dummy`
message to notify the sender of the new olm session.  The recipient may
assume that this `m.room_key.withheld` message applies to all encrypted
room messages sent before it receives the message.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `algorithm` | `string` | **yes** | The encryption algorithm for the key that this event is about. One of: `m.megolm.v1.aes-sha2`. |
| `room_id` | `string` | no | Required if `code` is not `m.no_olm`.  The room for the key that
this event is about. |
| `session_id` | `string` | no | Required if `code` is not `m.no_olm`.  The session ID of the key
that this event is about. |
| `sender_key` | `string` | **yes** | The unpadded base64-encoded device curve25519 key of the event\'s
sender. |
| `code` | `string` | **yes** | A machine-readable code for why the key was not sent. Codes beginning
with `m.` are reserved for codes defined in the Matrix
specification. Custom codes must use the Java package naming
convention. One of: `m.blacklisted`, `m.unverified`, `m.unauthorised`, `m.unavailable`, `m.no_olm`. |
| `reason` | `string` | no | A human-readable reason for why the key was not sent. The receiving
client should only use this string if it does not understand the
`code`. |

<details><summary>Example</summary>

```json
{
  "type": "m.room_key.withheld",
  "content": {
    "algorithm": "m.megolm.v1.aes-sha2",
    "room_id": "!Cuyf34gef24t:localhost",
    "session_id": "X3lUlvLELLYxeTx4yOVu6UDpasGEVO0Jbu+QFnm0cKQ",
    "sender_key": "RF3s+E7RkTQTGF2d8Deol0FkQvgII2aJDf3/Jp5mxVU",
    "code": "m.unverified",
    "reason": "Device not verified"
  }
}
```

</details>

---


### `m.room_key_request`

This event type is used to request keys for end-to-end encryption. It is sent as an
unencrypted [to-device](/client-server-api/#send-to-device-messaging) event.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `body` | `object` | no | Information about the requested key. Required when `action` is
`request`. Contains: `algorithm` (string): The encryption algorithm the requested key in this event is to be used
with.; `room_id` (string): The room where the key is used.; `sender_key` (string): The Curve25519 key of the device which initiated the session originally. **Deprecated**: This field provides no additional security or privacy benefit
and must not be read from. It should still be included on outgoing messages
(if the event for which keys are being requested for *also* has a `sender_key`),
however must not be used to find the corresponding session. See [`m.megolm.v1.aes-sha2`](/client-server-api/#mmegolmv1aes-sha2)
for more information.; `session_id` (string): The ID of the session that the key is for.. |
| `action` | `string` | **yes** |  One of: `request`, `request_cancellation`. |
| `requesting_device_id` | `string` | **yes** | ID of the device requesting the key. |
| `request_id` | `string` | **yes** | A random string uniquely identifying the request for a key. If the key is
requested multiple times, it should be reused. It should also reused in order
to cancel a request. |

---


### `m.secret.request`

Sent by a client to request a secret from another device or to cancel a
previous request. It is sent as an unencrypted to-device event.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `name` | `string` | no | Required if `action` is `request`. The name of the secret that is
being requested. |
| `action` | `string` | **yes** |  One of: `request`, `request_cancellation`. |
| `requesting_device_id` | `string` | **yes** | The ID of the device requesting the secret. |
| `request_id` | `string` | **yes** | A random string uniquely identifying (with respect to the requester
and the target) the target for a secret. If the secret is requested
from multiple devices at the same time, the same ID MAY be used for
every target. The same ID is also used in order to cancel a previous
request. |

<details><summary>Example</summary>

```json
{
  "type": "m.secret.request",
  "content": {
    "name": "org.example.some.secret",
    "action": "request",
    "requesting_device_id": "ABCDEFG",
    "request_id": "randomly_generated_id_9573"
  }
}
```

</details>

---


### `m.secret.send`

Sent by a client to share a secret with another device, in response to an
`m.secret.request` event. It must be encrypted as an `m.room.encrypted` event
using [Olm](/client-server-api/#molmv1curve25519-aes-sha2), then sent as a
to-device event.

The `request_id` must match the ID previously given in an `m.secret.request`
event. The recipient must ensure that this event comes from a device that the
`m.secret.request` event was originally sent to, and that the device is
a verified device owned by the recipient. This should be done by checking the
sender key of the Olm session that the event was sent over.

- **Kind:** Basic event


#### Content Fields

| Field | Type | Req? | Description |
|-------|------|------|-------------|
| `request_id` | `string` | **yes** | The ID of the request that this is a response to. |
| `secret` | `string` | **yes** | The contents of the secret |

<details><summary>Example</summary>

```json
{
  "type": "m.secret.send",
  "content": {
    "request_id": "randomly_generated_id_9573",
    "secret": "ThisIsASecretDon'tTellAnyone"
  }
}
```

</details>

---

## Common Content Sub-Objects

These are shared structures that appear inside `content` across many event types.

### `m.relates_to`

Used to create relationships between events (replies, edits, threads, reactions).

```json
{
  "m.relates_to": {
    "rel_type": "m.annotation",
    "event_id": "$target_event_id",
    "key": "👍"
  }
}
```

| `rel_type` value | Meaning |
|------------------|---------|
| `m.annotation` | Reaction |
| `m.reference` | Generic reference |
| `m.replace` | Edit / replacement |
| `m.thread` | Thread reply |

For replies (`m.in_reply_to`):
```json
{
  "m.relates_to": {
    "m.in_reply_to": {
      "event_id": "$original_event_id"
    }
  }
}
```

### `m.mentions`

Intentional mentions (added in Matrix v1.7):

```json
{
  "m.mentions": {
    "user_ids": ["@alice:example.org"],
    "room": false
  }
}
```

### Media `info` Object

Shared by `m.image`, `m.video`, `m.audio`, `m.file`, and `m.sticker` content types:

| Field | Type | Description |
|-------|------|-------------|
| `mimetype` | string | MIME type (e.g. `image/png`) |
| `size` | integer | File size in bytes |
| `w` | integer | Width in pixels (images/video) |
| `h` | integer | Height in pixels (images/video) |
| `duration` | integer | Duration in milliseconds (audio/video) |
| `thumbnail_url` | string | `mxc://` URI for thumbnail |
| `thumbnail_info` | object | `ThumbnailInfo` with `mimetype`, `size`, `w`, `h` |

---

*Source: [matrix-org/matrix-spec](https://github.com/matrix-org/matrix-spec) event schemas.
Spec version: latest (fetched at generation time).*
