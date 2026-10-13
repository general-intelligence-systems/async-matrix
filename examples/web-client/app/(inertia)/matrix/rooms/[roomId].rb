# frozen_string_literal: true

# /matrix/rooms/:roomId — Room
#
# Fractal: session_view/room_history/ | session_view/invite.blp | invite_request.blp
#
# THE TIMELINE, and the three-way render Fractal does in one stack:
# content.blp switches room-history | invite | invite-request on the room's
# category, so this is one route with three renderings rather than three
# routes. Reads matrix_timeline_chunks/entries for order and gaps, not an
# ORDER BY origin_server_ts.
# ── Fractal's widget tree ──────────────────────────────────────────────────
#
# COMPONENT NAMES ONLY, extracted from the Blueprint sources named below --
# properties, bindings, styles and handlers are dropped. This is the STRUCTURE
# to rebuild, not a prescription: an Adw.ActionRow is a GTK list row, and what
# it becomes in shadcn/reui is the next decision, not one this records.
#
# Adw.* is libadwaita, which is where the patterns live (PreferencesPage ->
# PreferencesGroup -> ActionRow is GNOME's settings idiom). Gtk.* is plain
# GTK. A bare <Name> with no prefix is one of Fractal's own widgets, and gets
# its own tree below if this view is where it is built.
#
# session_view/room_history/mod.blp
#
#   <Adw.Bin id="ContentRoomHistory">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar id="header_bar">
#         <RoomHistoryTitle id="room_title" />
#         <Gtk.MenuButton id="room_menu" />
#       </Adw.HeaderBar>
#       <Gtk.Box slot="content">
#         <Adw.Banner />
#         <ContentVerificationInfoBar id="verification_info_bar" />
#         <Adw.Banner id="pending_knocks_banner" />
#         <Gtk.Stack id="stack">
#           <Gtk.StackPage>
#             <Adw.Spinner slot="child" id="loading" />
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <Adw.StatusPage slot="child" id="error">
#               <Gtk.Button slot="child" />
#             </Adw.StatusPage>
#           </Gtk.StackPage>
#           <Gtk.StackPage>
#             <Gtk.Overlay slot="child" id="content">
#               <Gtk.Revealer id="scroll_btn_revealer">
#                 <Gtk.Button id="scroll_btn" />
#               </Gtk.Revealer>
#               <DragOverlay id="drag_overlay">
#                 <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#                   <Adw.ClampScrollable slot="child">
#                     <Gtk.ListView slot="child" id="listview" />
#                   </Adw.ClampScrollable>
#                 </Gtk.ScrolledWindow>
#               </DragOverlay>
#             </Gtk.Overlay>
#           </Gtk.StackPage>
#         </Gtk.Stack>
#         <Adw.Clamp>
#           <MessageToolbar id="message_toolbar" />
#         </Adw.Clamp>
#       </Gtk.Box>
#     </Adw.ToolbarView>
#   </Adw.Bin>
#
# session_view/room_history/title.blp
#
#   <Adw.Bin id="RoomHistoryTitle">
#     <Gtk.Button id="button">
#       <Gtk.Box slot="child">
#         <Gtk.Label />
#         <Gtk.Label id="subtitle_label" />
#       </Gtk.Box>
#     </Gtk.Button>
#   </Adw.Bin>
#
# session_view/room_history/message_row/mod.blp
#
#   <Adw.Bin id="ContentMessageRow">
#     <Gtk.Grid>
#       <Gtk.Button id="avatar_button">
#         <Avatar slot="child" id="avatar" />
#       </Gtk.Button>
#       <Gtk.Box id="header">
#         <ContentMessageSenderName id="display_name" />
#         <EventTimestamp id="timestamp" />
#       </Gtk.Box>
#       <ContentMessageContent id="content" />
#       <MessageStateStack id="message_state" />
#       <ContentMessageReactionList id="reactions" />
#       <ContentReadReceiptsList id="read_receipts" />
#     </Gtk.Grid>
#   </Adw.Bin>
#
# session_view/room_history/message_row/sender_name.blp
#
#   <Adw.Bin id="ContentMessageSenderName">
#     <Gtk.Label id="label" />
#   </Adw.Bin>
#
# session_view/room_history/message_row/reply.blp
#
#   <Gtk.Grid id="ContentMessageReply">
#     <Gtk.Grid>
#       <Gtk.Label id="related_content_sender" />
#       <Adw.Bin id="related_content" />
#     </Gtk.Grid>
#     <Adw.Bin id="content" />
#   </Gtk.Grid>
#
# session_view/room_history/message_row/visual_media.blp
#
#   <Gtk.Widget id="ContentMessageVisualMedia">
#     <Gtk.Overlay id="overlay">
#       <Gtk.Stack id="stack">
#         <Gtk.StackPage>
#           <Adw.Bin slot="child" />
#         </Gtk.StackPage>
#       </Gtk.Stack>
#       <Gtk.Box id="preview_instructions">
#         <Gtk.Image id="preview_instructions_icon" />
#         <Gtk.Label />
#       </Gtk.Box>
#       <Adw.Spinner id="spinner" />
#       <Gtk.Button id="hide_preview_button" />
#       <Gtk.Image id="error" />
#     </Gtk.Overlay>
#   </Gtk.Widget>
#
# session_view/room_history/message_row/file.blp
#
#   <Adw.Bin id="ContentMessageFile">
#     <Gtk.Box>
#       <Gtk.Image />
#       <Gtk.Label />
#       <Gtk.Button id="save" />
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_history/message_row/audio.blp
#
#   <Gtk.Box id="ContentMessageAudio">
#     <Gtk.Box>
#       <Gtk.Image />
#       <Gtk.Label />
#     </Gtk.Box>
#     <AudioPlayer id="player" />
#   </Gtk.Box>
#
# session_view/room_history/message_row/location.blp
#
#   <Widget id="ContentMessageLocation">
#     <Gtk.Overlay id="overlay">
#       <LocationViewer id="location" />
#       <Gtk.Image id="overlay_error" />
#     </Gtk.Overlay>
#   </Widget>
#
# session_view/room_history/message_row/info.blp
#
#   <Gtk.Grid id="ContentMessageInfo">
#     <Gtk.Image id="icon" />
#     <Gtk.Label id="label" />
#   </Gtk.Grid>
#
# session_view/room_history/message_row/message_state_stack.blp
#
#   <Adw.Bin id="MessageStateStack">
#     <Gtk.Stack id="stack">
#       <Gtk.StackPage>
#         <Adw.Bin slot="child" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.Spinner slot="child" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Gtk.Image slot="child" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Gtk.Image slot="child" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Gtk.Image slot="child" />
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Gtk.Image slot="child" />
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.Bin>
#
# session_view/room_history/message_row/reaction_list.blp
#
#   <Adw.Bin id="ContentMessageReactionList">
#     <Gtk.FlowBox id="flow_box" />
#   </Adw.Bin>
#
# session_view/room_history/message_row/reaction/mod.blp
#
#   <Gtk.FlowBoxChild id="ContentMessageReaction">
#     <Gtk.ToggleButton id="button">
#       <Gtk.Box>
#         <Gtk.Label id="reaction_key" />
#         <Gtk.Label id="reaction_count" />
#       </Gtk.Box>
#       <Gtk.GestureClick id="click_gesture" />
#       <Gtk.GestureLongPress id="long_press_gesture" />
#     </Gtk.ToggleButton>
#   </Gtk.FlowBoxChild>
#
# session_view/room_history/message_row/reaction/reaction_popover.blp
#
#   <Gtk.Popover id="ContentMessageReactionPopover">
#     <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#       <Gtk.ListView slot="child" id="list">
#         <Gtk.BuilderListItemFactory slot="factory">
#           <ContentMemberTimestampRow slot="child" />
#         </Gtk.BuilderListItemFactory>
#       </Gtk.ListView>
#     </Gtk.ScrolledWindow>
#   </Gtk.Popover>
#
# session_view/room_history/event_timestamp.blp
#
#   <Adw.Bin id="EventTimestamp">
#     <Gtk.Label id="label" />
#   </Adw.Bin>
#
# session_view/room_history/member_timestamp/row.blp
#
#   <Adw.Bin id="ContentMemberTimestampRow">
#     <Gtk.Box>
#       <Avatar />
#       <Gtk.Box>
#         <Gtk.Label />
#         <Gtk.Label id="timestamp" />
#       </Gtk.Box>
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_history/divider_row.blp
#
#   <Adw.Bin id="ContentDividerRow">
#     <Gtk.Box slot="child">
#       <Gtk.Separator />
#       <Gtk.Label id="inner_label" />
#       <Gtk.Separator />
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_history/typing_row.blp
#
#   <Adw.Bin id="ContentTypingRow">
#     <Gtk.Revealer>
#       <Gtk.Box slot="child">
#         <OverlappingAvatars id="avatar_list" />
#         <Gtk.Label id="label" />
#       </Gtk.Box>
#     </Gtk.Revealer>
#   </Adw.Bin>
#
# session_view/room_history/call_row.blp
#
#   <Adw.Bin id="CallRow">
#     <Gtk.Grid>
#       <Gtk.Image id="icon" />
#       <Gtk.Label id="inner_label" />
#       <EventTimestamp id="timestamp" />
#       <ContentReadReceiptsList id="read_receipts" />
#     </Gtk.Grid>
#   </Adw.Bin>
#
# session_view/room_history/state/row.blp
#
#   <Adw.Bin id="ContentStateRow">
#     <Gtk.Box slot="child">
#       <ContentStateContent />
#       <ContentReadReceiptsList id="read_receipts" />
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_history/state/group_row.blp
#
#   <Adw.Bin id="ContentStateGroupRow">
#     <Gtk.Box slot="child">
#       <Gtk.Box>
#         <Gtk.Label id="label" />
#         <Gtk.Image id="arrow" />
#         <Gtk.GestureClick />
#       </Gtk.Box>
#       <Gtk.Revealer>
#         <Gtk.ListBox slot="child" id="list_box" />
#       </Gtk.Revealer>
#       <ContentReadReceiptsList id="read_receipts" />
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_history/state/creation.blp
#
#   <Adw.Bin id="ContentStateCreation">
#     <Gtk.Box>
#       <Gtk.Label id="description" />
#       <Gtk.Button id="previous_room_btn" />
#     </Gtk.Box>
#   </Adw.Bin>
#
# session_view/room_history/read_receipts_list/mod.blp
#
#   <Gtk.Widget id="ContentReadReceiptsList">
#     <Gtk.Box id="content">
#       <Gtk.Label id="label" />
#       <OverlappingAvatars id="avatar_list" />
#     </Gtk.Box>
#     <Gtk.GestureClick />
#   </Gtk.Widget>
#
# session_view/room_history/read_receipts_list/read_receipts_popover.blp
#
#   <Gtk.Popover id="ContentReadReceiptsPopover">
#     <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#       <Gtk.ListView slot="child" id="list">
#         <Gtk.BuilderListItemFactory slot="factory">
#           <ContentMemberTimestampRow slot="child" />
#         </Gtk.BuilderListItemFactory>
#       </Gtk.ListView>
#     </Gtk.ScrolledWindow>
#   </Gtk.Popover>
#
# session_view/room_history/message_toolbar/mod.blp
#
#   <Adw.Bin id="MessageToolbar">
#     <Gtk.Stack id="main_stack">
#       <Gtk.StackPage>
#         <Gtk.Box slot="child">
#           <Gtk.Box id="related_event_toolbar">
#             <Gtk.Box>
#               <LabelWithWidgets id="related_event_header" />
#               <ContentMessageContent id="related_event_content" />
#               <Gtk.GestureClick />
#             </Gtk.Box>
#             <Gtk.Button />
#           </Gtk.Box>
#           <Gtk.Box>
#             <Gtk.Button id="attach_button" />
#             <Gtk.Button />
#             <CustomEntry>
#               <Gtk.ScrolledWindow>
#                 <GtkSource.View slot="child" id="message_entry">
#                   <Gtk.EventControllerKey />
#                 </GtkSource.View>
#               </Gtk.ScrolledWindow>
#             </CustomEntry>
#             <Gtk.MenuButton />
#             <Gtk.Button id="send_button" />
#           </Gtk.Box>
#         </Gtk.Box>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.Clamp slot="child">
#           <Gtk.Label slot="child" />
#         </Adw.Clamp>
#       </Gtk.StackPage>
#       <Gtk.StackPage>
#         <Adw.Clamp slot="child">
#           <Adw.WrapBox slot="child">
#             <Gtk.Label id="tombstoned_label" />
#             <LoadingButton id="tombstoned_button" />
#           </Adw.WrapBox>
#         </Adw.Clamp>
#       </Gtk.StackPage>
#     </Gtk.Stack>
#   </Adw.Bin>
#
# session_view/room_history/message_toolbar/attachment_dialog.blp
#
#   <Adw.Dialog id="AttachmentDialog">
#     <Adw.ToolbarView slot="child">
#       <Adw.HeaderBar>
#         <Gtk.Button id="cancel_button" />
#         <Gtk.Button id="send_button" />
#       </Adw.HeaderBar>
#       <MediaContentViewer slot="content" id="media" />
#     </Adw.ToolbarView>
#   </Adw.Dialog>
#
# session_view/room_history/message_toolbar/completion/completion_popover.blp
#
#   <Gtk.Popover id="ContentCompletionPopover">
#     <Gtk.ScrolledWindow slot="child" id="scrolled_window">
#       <Gtk.ListBox slot="child" id="list" />
#     </Gtk.ScrolledWindow>
#   </Gtk.Popover>
#
# session_view/room_history/event_actions/context_menu.blp
#
#
# session_view/room_history/event_actions/quick_reaction_chooser.blp
#
#   <Adw.Bin id="QuickReactionChooser">
#     <Gtk.Grid slot="child" id="reaction_grid">
#       <Gtk.Button />
#     </Gtk.Grid>
#   </Adw.Bin>
#
# session_view/room_history/verification_info_bar.blp
#
#   <Adw.Bin id="ContentVerificationInfoBar">
#     <Gtk.Revealer id="revealer">
#       <Gtk.Box slot="child">
#         <Gtk.Label id="label" />
#         <LoadingButton id="accept_btn" />
#         <LoadingButton id="cancel_btn" />
#       </Gtk.Box>
#     </Gtk.Revealer>
#   </Adw.Bin>
#
# session_view/invite.blp
#
#   <Adw.Bin id="ContentInvite">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar id="header_bar">
#         <Adw.WindowTitle />
#       </Adw.HeaderBar>
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Avatar id="avatar" />
#             <Gtk.Box>
#               <Gtk.Label id="display_name" />
#               <Gtk.Label id="room_alias" />
#             </Gtk.Box>
#             <Gtk.Label id="room_topic" />
#             <LabelWithWidgets id="inviter" />
#             <Gtk.Box>
#               <LoadingButton id="decline_button" />
#               <LoadingButton id="accept_button" />
#             </Gtk.Box>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.Bin>
#
# session_view/invite_request.blp
#
#   <Adw.Bin id="ContentInviteRequest">
#     <Adw.ToolbarView>
#       <Adw.HeaderBar id="header_bar">
#         <Adw.WindowTitle />
#       </Adw.HeaderBar>
#       <Gtk.ScrolledWindow slot="content">
#         <Adw.Clamp slot="child">
#           <Gtk.Box slot="child">
#             <Avatar id="avatar" />
#             <Gtk.Box>
#               <Gtk.Label id="display_name" />
#               <Gtk.Label id="room_alias" />
#             </Gtk.Box>
#             <Gtk.Label id="room_topic" />
#             <Gtk.Label />
#             <Gtk.Box>
#               <LoadingButton id="retract_button" />
#             </Gtk.Box>
#           </Gtk.Box>
#         </Adw.Clamp>
#       </Gtk.ScrolledWindow>
#     </Adw.ToolbarView>
#   </Adw.Bin>
#
# ── Build with ─────────────────────────────────────────────────────────────
#
# @reui/ai-chat-1 — "AI copilot chat surface with streaming transcript and recent
#   chats". The structural base: full-page transcript, avatars, alternating alignment,
#   code blocks inside messages, and a docked composer. Seen in the browser and it is
#   the Matrix message layout almost exactly.
#
#   ai-chat-11 is already installed and you asked to build on it, so take its
#   primitives (message, message-scroller, bubble, marker, item, input-group, kbd,
#   frame) and take ai-chat-1 for the ARRANGEMENT. What does not port from 11 is
#   answer-slab and stage-header: those are single-assistant furniture, and a room has
#   many senders.
#
#   THE SCROLLER IS THE PART TO KEEP. MessageScroller stays pinned to the bottom until
#   the reader scrolls up -- the one piece of chat behaviour that is tedious to write
#   and easy to get subtly wrong.
#
#   Gtk.ListView + ClampScrollable              ->  ui/message-scroller — pinned-until-scrolled,
#                                                    then release
#   MessageRow                                  ->  ui/message + ui/bubble
#   EventHeaderState Full/TimestampOnly/Hidden  ->  no component — sender grouping is ours to write
#   SenderName + Adw.Avatar                     ->  ui/avatar + ui/badge for the power-level flag
#   DividerRow (DayDivider)                     ->  ui/separator with a centred label
#   DividerRow (NewMessages)                    ->  ui/marker — m.fully_read, visually distinct from
#                                                    a day break
#   MessageReply                                ->  ui/bubble nested, muted
#   ReactionList / ReactionGroup                ->  ui/toggle-group — a reaction is a toggle you are
#                                                    in or out of
#   QuickReactionChooser                        ->  ui/popover + ui/toggle-group
#   EventActions ContextMenu                    ->  ui/context-menu — right-click, as GTK does
#   MessageStateStack                           ->  ui/spinner / ui/badge — Sending,
#                                                    RecoverableError, PermanentError
#   ReadReceiptsList + popover                  ->  stacked ui/avatar + ui/hover-card
#   TypingRow                                   ->  ui/item + the block's own typing dots
#   StateRow / StateGroupRow                    ->  ui/item, muted — membership and state changes
#   CallRow                                     ->  reui/alert
#   Adw.Banner (verification, knocks)           ->  reui/alert — already vendored
#   MessageToolbar                              ->  ui/input-group — the block's composer:
#                                                    attachment chips, stop control
#   CompletionPopover (@mentions)               ->  the composer's trigger-character palette,
#                                                    verbatim
#   AttachmentDialog                            ->  ui/dialog + file-upload
#   VisualMedia / File / Audio / Location       ->  ui/card variants; audio-player is its own thing
#   MessageInfo (code, formatted body)          ->  reui/code-block for <pre>, inside the bubble
#   Adw.Spinner / StatusPage                    ->  ui/spinner / ui/empty
#   Pill (mentions in body)                     ->  ui/badge + ui/hover-card
#
# INSTALL, plain shadcn: hover-card
# INSTALL, reui registry: @reui/code-block
# INSTALL, NOT IN EITHER REGISTRY -- reui lists file-upload/attachment on its components page but the
#   base-vega registry does not carry it; check the name before relying on it.
#
# NO CATALOG MATCH, hand-build:
#   EventHeaderState grouping, and the gap/pagination affordance -- nothing in the
#   catalog knows that a timeline can have holes in the middle (matrix_timeline_chunks
#   kind='gap'). Both are ours.
#
# RENDERS THREE THINGS, not one. Fractal's content.blp is a stack whose page is
# chosen by the room's category -- room-history, invite, or invite-request --
# so a joined room, an invite and a knock are one route with three renderings
# rather than three routes.

get "/" do
  room = Models::Matrix::Room.first(room_id: params["roomId"]) || halt(404, "matrix: no such room\n")
  me = Models::Matrix::Credential.first&.matrix_user_id.to_s

  render(
    "matrix/rooms/[roomId]",
    room:   {
      roomId:      room.room_id,
      title:       room.title,
      avatarUrl:   room.avatar_url,
      topic:       room.topic,
      encrypted:   room.encrypted,
      direct:      room.direct,
      membership:  room.membership,
      memberCount: room.joined_member_count.to_i,
      # Who invited us: the sender of our own m.room.member event, which is the
      # only place an invite carries it.
      invitedBy:   Models::Matrix::RoomState.first(
        room_id: room.room_id, event_type: "m.room.member", state_key: me,
      )&.sender,
    },
    events: room.events.main_timeline.chronological.limit(200).all.map{|event|
      {
        eventId:         event.event_id,
        type:            event.type,
        sender:          event.sender,
        senderName:      event.sender_name,
        senderAvatar:    event.sender_avatar_url,
        body:            event.content["body"],
        msgtype:         event.content["msgtype"],
        media:           Matrix::RoomActions.media_url(event.content["url"]),
        mimetype:        event.content.dig("info", "mimetype"),
        size:            event.content.dig("info", "size"),
        formatted:       event.formatted_body,
        ts:              event.origin_server_ts.to_i,
        edited:          event.edited?,
        redacted:        event.redacted?,
        decryptionError: event.decryption_error,
        stateKey:        event.state_key,
        replyToId:       event.reply_to_id,
        reactions:       event.reactions(me),
      }
    },
    # Who we are, so the view can align our own messages to the end the way
    # Message's align="end" expects.
    selfId: me,
  )
end

post "/" do
  room_id = room_id!

  act! do
    case params["action"].to_s
    when "", "send"
      Matrix::RoomActions.send_message(
        room_id,
        params["body"].to_s,
        reply_to: params["reply_to"],
        edits:    params["edits"],
      )
    when "attach"
      upload = params["file"]

      if upload.nil?
        halt(422, "matrix: no file\n")
      end

      Matrix::RoomActions.send_attachment(
        room_id,
        upload[:tempfile].read,
        upload[:type].to_s,
        upload[:filename].to_s,
      )
    when "redact"
      Matrix::RoomActions.redact(room_id, params["event_id"].to_s, reason: params["reason"])
    when "react"
      Matrix::RoomActions.react(room_id, params["event_id"].to_s, params["key"].to_s)
    when "report"
      Matrix::RoomActions.report(room_id, params["event_id"].to_s, reason: params["reason"])
    when "cancel-send"
      Matrix::RoomActions.abort!(room_id, params["transaction_id"].to_s)
    when "typing"
      Matrix::RoomActions.set_typing(room_id, params["typing"].to_s == "true")
    when "receipt"
      Matrix::RoomActions.send_receipt(room_id, params["event_id"].to_s, thread_id: params["thread_id"])
    when "fully-read"
      Matrix::RoomActions.set_fully_read(room_id, params["event_id"].to_s)
    when "mark-unread"
      Matrix::RoomActions.mark_unread(room_id, params["unread"].to_s == "true")
    when "category"
      Matrix::RoomActions.set_category(room_id, params["category"].to_s)
    when "join"
      Matrix::RoomActions.join(room_id)
    when "leave"
      Matrix::RoomActions.leave(room_id)
    when "forget"
      Matrix::RoomActions.forget(room_id)
    else
      halt(422, "matrix: unknown action\n")
    end
  end
end

__END__

import { Form, Head, Link, router } from "@inertiajs/react"
import { useRef } from "react"
import {
  ArrowLeft,
  Lock,
  Paperclip,
  Send,
  Settings2,
  ShieldAlert,
  Users,
} from "lucide-react"

import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Badge } from "@/components/reui/badge"
import { Button } from "@/components/ui/button"
import { Empty, EmptyDescription, EmptyHeader, EmptyMedia, EmptyTitle } from "@/components/ui/empty"
import {
  InputGroup,
  InputGroupAddon,
  InputGroupButton,
  InputGroupTextarea,
} from "@/components/ui/input-group"
import {
  Message,
  MessageAvatar,
  MessageContent,
  MessageFooter,
  MessageGroup,
  MessageHeader,
} from "@/components/ui/message"
import {
  MessageScroller,
  MessageScrollerButton,
  MessageScrollerContent,
  MessageScrollerProvider,
  MessageScrollerViewport,
} from "@/components/ui/message-scroller"
import { Separator } from "@/components/ui/separator"
import { Tooltip, TooltipContent, TooltipTrigger } from "@/components/ui/tooltip"
import { cn } from "cn"
import { ShellHeader } from "@/components/admin/slots"

type Room = {
  roomId: string
  title: string
  avatarUrl: string | null
  topic: string | null
  encrypted: boolean
  direct: boolean
  membership: string
  memberCount: number
  invitedBy: string | null
}

type Reaction = { key: string; count: number; mine: boolean }

type Event = {
  eventId: string
  type: string
  sender: string
  senderName: string
  senderAvatar: string | null
  body: string | null
  msgtype: string | null
  media: string | null
  mimetype: string | null
  size: number | null
  formatted: string | null
  ts: number
  edited: boolean
  redacted: boolean
  decryptionError: string | null
  stateKey: string | null
  replyToId: string | null
  reactions: Reaction[]
}

const time = (ts: number) =>
  new Date(ts).toLocaleTimeString(undefined, { hour: "2-digit", minute: "2-digit" })

const day = (ts: number) =>
  new Date(ts).toLocaleDateString(undefined, { weekday: "long", day: "numeric", month: "long" })

const initial = (name: string) => name.replace(/^[#!@]/, "").charAt(0).toUpperCase()

// A state event renders as a muted one-liner, not a bubble -- Fractal's
// StateRow. Keeping them in the stream is what makes "Alice joined" sit in
// order with the messages around it.
const STATE_TYPES = new Set([
  "m.room.member",
  "m.room.name",
  "m.room.topic",
  "m.room.avatar",
  "m.room.canonical_alias",
  "m.room.join_rules",
  "m.room.history_visibility",
  "m.room.guest_access",
  "m.room.power_levels",
  "m.room.encryption",
  "m.room.create",
  "m.room.tombstone",
])

function StateRow({ event }: { event: Event }) {
  return (
    <div className="px-3 py-0.5 text-xs text-muted-foreground">
      <span className="font-medium">{event.senderName}</span> {event.body ?? event.type}
    </div>
  )
}

function DayDivider({ ts }: { ts: number }) {
  return (
    <div className="flex items-center gap-3 py-3">
      <Separator className="flex-1" />
      <span className="text-xs font-medium text-muted-foreground">{day(ts)}</span>
      <Separator className="flex-1" />
    </div>
  )
}

function Reactions({ reactions }: { reactions: Reaction[] }) {
  return (
    <div className="flex flex-wrap gap-1 pt-0.5">
      {reactions.map((reaction) => (
        <button
          key={reaction.key}
          type="button"
          className={cn(
            "rounded-full border px-1.5 py-0.5 text-xs transition-colors",
            reaction.mine
              ? "border-primary/40 bg-primary/10"
              : "border-transparent bg-muted hover:bg-muted/70"
          )}
        >
          <span className="mr-1">{reaction.key}</span>
          <span className="tabular-nums text-muted-foreground">{reaction.count}</span>
        </button>
      ))}
    </div>
  )
}

function MessageRow({
  event,
  own,
  showHeader,
}: {
  event: Event
  own: boolean
  showHeader: boolean
}) {
  return (
    <Message align={own ? "end" : "start"}>
      {/* The avatar slot is held even when the header is hidden, so a run of
          messages from one sender stays aligned with the first. */}
      <MessageAvatar className={cn(!showHeader && "invisible")}>
        <Avatar className="size-8">
          {event.senderAvatar && <AvatarImage src={event.senderAvatar} alt="" />}
          <AvatarFallback className="text-[11px]">{initial(event.senderName)}</AvatarFallback>
        </Avatar>
      </MessageAvatar>

      <MessageContent>
        {showHeader && (
          <MessageHeader>
            <span className="font-medium text-foreground">{event.senderName}</span>
          </MessageHeader>
        )}

        <div
          className={cn(
            "w-fit max-w-prose rounded-lg px-3 py-1.5",
            own ? "bg-primary text-primary-foreground" : "bg-muted",
            event.redacted && "italic opacity-60",
            event.decryptionError && "border border-dashed bg-transparent"
          )}
        >
          {event.decryptionError ? (
            <span className="flex items-center gap-1.5 text-sm text-muted-foreground">
              <ShieldAlert className="size-3.5" />
              Unable to decrypt
            </span>
          ) : event.redacted ? (
            <span className="text-sm">Message deleted</span>
          ) : event.media && event.msgtype === "m.image" ? (
            <a href={event.media} target="_blank" rel="noreferrer">
              <img
                src={event.media}
                alt={event.body ?? ""}
                className="max-h-80 max-w-full rounded"
              />
            </a>
          ) : event.media && event.msgtype === "m.video" ? (
            <video src={event.media} controls className="max-h-80 max-w-full rounded" />
          ) : event.media && event.msgtype === "m.audio" ? (
            <audio src={event.media} controls className="w-full" />
          ) : event.media ? (
            <a
              href={event.media}
              download={event.body ?? undefined}
              className="flex items-center gap-2 text-sm underline"
            >
              <Paperclip className="size-3.5" />
              {event.body}
              {event.size ? (
                <span className="text-xs opacity-70">({Math.ceil(event.size / 1024)} KB)</span>
              ) : null}
            </a>
          ) : event.formatted ? (
            <div
              className="text-sm [&_a]:underline [&_code]:rounded [&_code]:bg-black/10 [&_code]:px-1"
              dangerouslySetInnerHTML={{ __html: event.formatted }}
            />
          ) : (
            <span className="text-sm whitespace-pre-wrap">{event.body}</span>
          )}
        </div>

        {event.reactions.length > 0 && <Reactions reactions={event.reactions} />}

        <MessageFooter>
          <Tooltip>
            <TooltipTrigger render={<span className="tabular-nums">{time(event.ts)}</span>} />
            <TooltipContent>{new Date(event.ts).toLocaleString()}</TooltipContent>
          </Tooltip>
          {event.edited && <span className="ml-1">(edited)</span>}
        </MessageFooter>
      </MessageContent>
    </Message>
  )
}

function Timeline({ events, selfId }: { events: Event[]; selfId: string }) {
  if (events.length === 0) {
    return (
      <Empty className="flex-1">
        <EmptyHeader>
          <EmptyTitle>No messages yet</EmptyTitle>
          <EmptyDescription>Anything sent to this room will appear here.</EmptyDescription>
        </EmptyHeader>
      </Empty>
    )
  }

  // THE PROVIDER IS NOT OPTIONAL. MessageScrollerPrimitive.Root calls
  // useMessageScroller(), which throws "must be used within a MessageScroller"
  // when there is no provider above it -- so the whole timeline fails to
  // render rather than degrading. `autoScroll` is what keeps the view pinned
  // to the newest message, which is the behaviour the note at the top of this
  // file describes.
  return (
    <MessageScrollerProvider autoScroll>
      <MessageScroller className="min-h-0 flex-1">
        <MessageScrollerViewport>
          <MessageScrollerContent className="mx-auto flex w-full max-w-3xl flex-col gap-1 p-4">
            {events.map((event, index) => {
              const previous = events[index - 1]
              const newDay =
                !previous || new Date(previous.ts).toDateString() !== new Date(event.ts).toDateString()

              if (STATE_TYPES.has(event.type) && event.stateKey !== null) {
                return (
                  <div key={event.eventId}>
                    {newDay && <DayDivider ts={event.ts} />}
                    <StateRow event={event} />
                  </div>
                )
              }

              // EventHeaderState, decided here. Fractal has three values
              // (Full / TimestampOnly / Hidden); the header is dropped when the
              // previous event is the same sender, close in time, and not a
              // state row breaking the run.
              const sameSender =
                previous &&
                previous.sender === event.sender &&
                !STATE_TYPES.has(previous.type) &&
                event.ts - previous.ts < 5 * 60 * 1000

              return (
                <MessageGroup key={event.eventId}>
                  {newDay && <DayDivider ts={event.ts} />}
                  <MessageRow
                    event={event}
                    own={event.sender === selfId}
                    showHeader={!sameSender || newDay}
                  />
                </MessageGroup>
              )
            })}
          </MessageScrollerContent>
        </MessageScrollerViewport>

        {/* Pinned to the bottom until the reader scrolls up, then this appears. */}
        <MessageScrollerButton />
      </MessageScroller>
    </MessageScrollerProvider>
  )
}

function InvitePrompt({ room }: { room: Room }) {
  return (
    <Empty className="flex-1">
      <EmptyHeader>
        <EmptyMedia variant="icon">
          <Avatar className="size-12">
            {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
            <AvatarFallback>{initial(room.title)}</AvatarFallback>
          </Avatar>
        </EmptyMedia>
        <EmptyTitle>{room.title}</EmptyTitle>
        <EmptyDescription>
          {room.invitedBy ? `${room.invitedBy} invited you to this room.` : "You have been invited."}
          {room.topic && <span className="mt-2 block">{room.topic}</span>}
        </EmptyDescription>
      </EmptyHeader>
      <div className="flex gap-2">
        <Button>Accept</Button>
        <Button variant="outline">Decline</Button>
      </div>
    </Empty>
  )
}

function KnockPrompt({ room }: { room: Room }) {
  return (
    <Empty className="flex-1">
      <EmptyHeader>
        <EmptyTitle>Waiting to be let in</EmptyTitle>
        <EmptyDescription>
          You asked to join {room.title}. A moderator has to approve the request.
        </EmptyDescription>
      </EmptyHeader>
      <Button variant="outline">Cancel request</Button>
    </Empty>
  )
}

export default function MatrixRoom({
  room,
  events,
  selfId,
}: {
  room: Room
  events: Event[]
  selfId: string
}) {
  const encoded = encodeURIComponent(room.roomId)
  const attachment = useRef<HTMLInputElement>(null)

  return (
    <div className="flex min-h-0 flex-1 flex-col">
      <Head title={`${room.title} · matrix`} />

      <ShellHeader>
        <Link href="/matrix" className="text-muted-foreground hover:text-foreground md:hidden">
          <ArrowLeft className="size-4" />
        </Link>

        <Link href={`/matrix/rooms/${encoded}/about`} className="flex min-w-0 items-center gap-2">
          <Avatar className="size-7">
            {room.avatarUrl && <AvatarImage src={room.avatarUrl} alt="" />}
            <AvatarFallback className="text-[11px]">{initial(room.title)}</AvatarFallback>
          </Avatar>
          <div className="flex min-w-0 flex-col">
            <span className="truncate text-sm font-medium">{room.title}</span>
            {room.topic && (
              <span className="truncate text-xs text-muted-foreground">{room.topic}</span>
            )}
          </div>
        </Link>

        {room.encrypted && (
          <Tooltip>
            <TooltipTrigger render={<Lock className="size-3.5 shrink-0 text-muted-foreground" />} />
            <TooltipContent>End-to-end encrypted</TooltipContent>
          </Tooltip>
        )}

        <div className="ms-auto flex items-center gap-1">
          <Button variant="ghost" size="sm" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/members`} />}>
              <Users className="size-4" />
              {room.memberCount > 0 && (
                <span className="ml-1 tabular-nums">{room.memberCount}</span>
              )}
            </Button>
          <Button variant="ghost" size="sm" nativeButton={false} render={<Link href={`/matrix/rooms/${encoded}/about`} />}>
              <Settings2 className="size-4" />
            </Button>
        </div>
      </ShellHeader>

      {room.membership === "invite" ? (
        <InvitePrompt room={room} />
      ) : room.membership === "knock" ? (
        <KnockPrompt room={room} />
      ) : (
        <>
          <Timeline events={events} selfId={selfId} />

          {/* MessageToolbar. Enter sends, shift+Enter is a newline, and the paperclip posts the
              file on its own as multipart -- an attachment is an upload then a message, so it
              cannot ride along with the text. */}
          <div className="shrink-0 border-t p-3">
            <Form
              action={`/matrix/rooms/${encoded}`}
              method="post"
              resetOnSuccess
              className="mx-auto max-w-3xl"
            >
              {({ processing, submit }) => (
                <InputGroup>
                  <input type="hidden" name="action" value="send" />
                  <InputGroupTextarea
                    name="body"
                    placeholder={`Message ${room.title}`}
                    rows={1}
                    className="max-h-40"
                    disabled={processing}
                    onKeyDown={(event) => {
                      if (event.key === "Enter" && !event.shiftKey) {
                        event.preventDefault()
                        submit()
                      }
                    }}
                  />
                  <InputGroupAddon align="block-end">
                    <InputGroupButton
                      variant="ghost"
                      size="icon-xs"
                      aria-label="Attach"
                      type="button"
                      disabled={processing}
                      onClick={() => attachment.current?.click()}
                    >
                      <Paperclip className="size-4" />
                    </InputGroupButton>
                    {room.encrypted && (
                      <Badge variant="secondary" size="sm" className="ml-1">
                        <Lock className="size-2.5" />
                        Encrypted
                      </Badge>
                    )}
                    <InputGroupButton
                      size="icon-xs"
                      className="ms-auto"
                      aria-label="Send"
                      type="submit"
                      disabled={processing}
                    >
                      <Send className="size-4" />
                    </InputGroupButton>
                  </InputGroupAddon>
                </InputGroup>
              )}
            </Form>

            <input
              ref={attachment}
              type="file"
              className="hidden"
              onChange={(event) => {
                const file = event.target.files?.[0]
                if (!file) return
                router.post(
                  `/matrix/rooms/${encoded}`,
                  { action: "attach", file },
                  { forceFormData: true, preserveScroll: true },
                )
                event.target.value = ""
              }}
            />
          </div>
        </>
      )}
    </div>
  )
}
