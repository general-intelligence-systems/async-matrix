# frozen_string_literal: true

require_relative 'base'

# well_known (outside /_matrix prefix)
require_relative 'well_known/matrix/client'
require_relative 'well_known/matrix/support'
require_relative 'well_known/matrix/policy_server'

# client/versions
require_relative 'client/versions'

# client/v3
require_relative 'client/v3/login'
require_relative 'client/v3/logout'
require_relative 'client/v3/refresh'
require_relative 'client/v3/register'
require_relative 'client/v3/account'
require_relative 'client/v3/capabilities'
require_relative 'client/v3/sync'
require_relative 'client/v3/events'
require_relative 'client/v3/initialSync'
require_relative 'client/v3/user'
require_relative 'client/v3/rooms'
require_relative 'client/v3/createRoom'
require_relative 'client/v3/joined_rooms'
require_relative 'client/v3/join'
require_relative 'client/v3/knock'
require_relative 'client/v3/profile'
require_relative 'client/v3/presence'
require_relative 'client/v3/devices'
require_relative 'client/v3/delete_devices'
require_relative 'client/v3/keys'
require_relative 'client/v3/room_keys'
require_relative 'client/v3/pushrules'
require_relative 'client/v3/pushers'
require_relative 'client/v3/notifications'
require_relative 'client/v3/search'
require_relative 'client/v3/user_directory'
require_relative 'client/v3/directory'
require_relative 'client/v3/publicRooms'
require_relative 'client/v3/sendToDevice'
require_relative 'client/v3/voip'
require_relative 'client/v3/thirdparty'
require_relative 'client/v3/admin'
require_relative 'client/v3/users'

# client/v1
require_relative 'client/v1/login'
require_relative 'client/v1/register'
require_relative 'client/v1/auth_metadata'
require_relative 'client/v1/rooms'
require_relative 'client/v1/room_summary'
require_relative 'client/v1/admin'
require_relative 'client/v1/media'
require_relative 'client/v1/appservice'

# media
require_relative 'media/v1/create'
require_relative 'media/v3/upload'

# federation (server-server API)
require_relative 'well_known/matrix/server'
require_relative 'federation/v1/version'
require_relative 'federation/v1/send'
require_relative 'federation/v1/event'
require_relative 'federation/v1/event_auth'
require_relative 'federation/v1/backfill'
require_relative 'federation/v1/get_missing_events'
require_relative 'federation/v1/state'
require_relative 'federation/v1/state_ids'
require_relative 'federation/v1/timestamp_to_event'
require_relative 'federation/v1/make_join'
require_relative 'federation/v1/make_knock'
require_relative 'federation/v1/send_knock'
require_relative 'federation/v1/make_leave'
require_relative 'federation/v1/invite'
require_relative 'federation/v1/3pid'
require_relative 'federation/v1/exchange_third_party_invite'
require_relative 'federation/v1/publicRooms'
require_relative 'federation/v1/hierarchy'
require_relative 'federation/v1/query'
require_relative 'federation/v1/openid'
require_relative 'federation/v1/user'
require_relative 'federation/v1/media'
require_relative 'federation/v2/send_join'
require_relative 'federation/v2/send_leave'
require_relative 'federation/v2/invite'

# key (server keys)
require_relative 'key/v2/server'
require_relative 'key/v2/query'

# policy server
require_relative 'policy/v1/sign'

# application service API
require_relative 'app/v1/transactions'
require_relative 'app/v1/ping'
require_relative 'app/v1/users'
require_relative 'app/v1/rooms'
require_relative 'app/v1/thirdparty'

# identity service API
require_relative 'identity/versions'
require_relative 'identity/v2/status'
require_relative 'identity/v2/account'
require_relative 'identity/v2/terms'
require_relative 'identity/v2/pubkey'
require_relative 'identity/v2/hash_details'
require_relative 'identity/v2/lookup'
require_relative 'identity/v2/validate/email'
require_relative 'identity/v2/validate/msisdn'
require_relative 'identity/v2/3pid'
require_relative 'identity/v2/store_invite'
require_relative 'identity/v2/sign_ed25519'

# push gateway API
require_relative 'push/v1/notify'

module MatrixApi
  # Root mount point for the Matrix APIs.
  #
  # URL structure mirrors directory structure (minus _matrix prefix):
  #
  #   URL path                                      => File
  #   /.well-known/matrix/client                    => well_known/matrix/client.rb
  #   /.well-known/matrix/server                    => well_known/matrix/server.rb
  #   /_matrix/client/v3/login                      => client/v3/login.rb
  #   /_matrix/federation/v1/send/:txnId            => federation/v1/send.rb
  #   /_matrix/federation/v2/send_join/:r/:e        => federation/v2/send_join.rb
  #   /_matrix/key/v2/server                        => key/v2/server.rb
  #   /_matrix/policy/v1/sign                       => policy/v1/sign.rb
  #   ...etc
  #
  class API < Base
    # /.well-known routes live outside the _matrix prefix
    namespace '.well-known' do
      namespace :matrix do
        mount WellKnown::Matrix::Client       => '/client'
        mount WellKnown::Matrix::Support      => '/support'
        mount WellKnown::Matrix::PolicyServer => '/policy_server'
        mount WellKnown::Matrix::Server       => '/server'
      end
    end

    # Everything else lives under /_matrix
    namespace :_matrix do

      # ==================================================================
      # Client-Server API
      # ==================================================================

      # /_matrix/client
      namespace :client do
        mount Client::Versions => '/versions'

        # /_matrix/client/v3
        namespace :v3 do
          mount Client::V3::Login          => '/login'
          mount Client::V3::Logout         => '/logout'
          mount Client::V3::Refresh        => '/refresh'
          mount Client::V3::Register       => '/register'
          mount Client::V3::Account        => '/account'
          mount Client::V3::Capabilities   => '/capabilities'
          mount Client::V3::Sync           => '/sync'
          mount Client::V3::Events         => '/events'
          mount Client::V3::InitialSync    => '/initialSync'
          mount Client::V3::User           => '/user'
          mount Client::V3::Rooms          => '/rooms'
          mount Client::V3::CreateRoom     => '/createRoom'
          mount Client::V3::JoinedRooms    => '/joined_rooms'
          mount Client::V3::Join           => '/join'
          mount Client::V3::Knock          => '/knock'
          mount Client::V3::Profile        => '/profile'
          mount Client::V3::Presence       => '/presence'
          mount Client::V3::Devices        => '/devices'
          mount Client::V3::DeleteDevices  => '/delete_devices'
          mount Client::V3::Keys           => '/keys'
          mount Client::V3::RoomKeys       => '/room_keys'
          mount Client::V3::Pushrules      => '/pushrules'
          mount Client::V3::Pushers        => '/pushers'
          mount Client::V3::Notifications  => '/notifications'
          mount Client::V3::Search         => '/search'
          mount Client::V3::UserDirectory  => '/user_directory'
          mount Client::V3::Directory      => '/directory'
          mount Client::V3::PublicRooms    => '/publicRooms'
          mount Client::V3::SendToDevice   => '/sendToDevice'
          mount Client::V3::Voip           => '/voip'
          mount Client::V3::Thirdparty     => '/thirdparty'
          mount Client::V3::Admin          => '/admin'
          mount Client::V3::Users          => '/users'
        end

        # /_matrix/client/v1
        namespace :v1 do
          mount Client::V1::Login        => '/login'
          mount Client::V1::Register     => '/register'
          mount Client::V1::AuthMetadata => '/auth_metadata'
          mount Client::V1::Rooms        => '/rooms'
          mount Client::V1::RoomSummary  => '/room_summary'
          mount Client::V1::Admin        => '/admin'
          mount Client::V1::Media        => '/media'
          mount Client::V1::Appservice   => '/appservice'
        end
      end

      # /_matrix/media
      namespace :media do
        mount Media::V1::Create => '/v1/create'
        mount Media::V3::Upload => '/v3/upload'
      end

      # ==================================================================
      # Server-Server (Federation) API
      # ==================================================================

      # /_matrix/federation
      namespace :federation do
        # /_matrix/federation/v1
        namespace :v1 do
          mount Federation::V1::Version                  => '/version'
          mount Federation::V1::Send                     => '/send'
          mount Federation::V1::Event                    => '/event'
          mount Federation::V1::EventAuth                => '/event_auth'
          mount Federation::V1::Backfill                 => '/backfill'
          mount Federation::V1::GetMissingEvents         => '/get_missing_events'
          mount Federation::V1::State                    => '/state'
          mount Federation::V1::StateIds                 => '/state_ids'
          mount Federation::V1::TimestampToEvent         => '/timestamp_to_event'
          mount Federation::V1::MakeJoin                 => '/make_join'
          mount Federation::V1::MakeKnock                => '/make_knock'
          mount Federation::V1::SendKnock                => '/send_knock'
          mount Federation::V1::MakeLeave                => '/make_leave'
          mount Federation::V1::Invite                   => '/invite'
          mount Federation::V1::ThirdPid                 => '/3pid'
          mount Federation::V1::ExchangeThirdPartyInvite => '/exchange_third_party_invite'
          mount Federation::V1::PublicRooms              => '/publicRooms'
          mount Federation::V1::Hierarchy                => '/hierarchy'
          mount Federation::V1::Query                    => '/query'
          mount Federation::V1::Openid                   => '/openid'
          mount Federation::V1::User                     => '/user'
          mount Federation::V1::Media                    => '/media'
        end

        # /_matrix/federation/v2
        namespace :v2 do
          mount Federation::V2::SendJoin  => '/send_join'
          mount Federation::V2::SendLeave => '/send_leave'
          mount Federation::V2::Invite    => '/invite'
        end
      end

      # /_matrix/key
      namespace :key do
        namespace :v2 do
          mount Key::V2::Server => '/server'
          mount Key::V2::Query  => '/query'
        end
      end

      # /_matrix/policy
      namespace :policy do
        namespace :v1 do
          mount Policy::V1::Sign => '/sign'
        end
      end

      # ==================================================================
      # Application Service API
      # ==================================================================

      # /_matrix/app
      namespace :app do
        namespace :v1 do
          mount App::V1::Transactions => '/transactions'
          mount App::V1::Ping         => '/ping'
          mount App::V1::Users        => '/users'
          mount App::V1::Rooms        => '/rooms'
          mount App::V1::Thirdparty   => '/thirdparty'
        end
      end

      # ==================================================================
      # Identity Service API
      # ==================================================================

      # /_matrix/identity
      namespace :identity do
        mount Identity::Versions => '/versions'

        namespace :v2 do
          mount Identity::V2::Status      => '/'
          mount Identity::V2::Account     => '/account'
          mount Identity::V2::Terms       => '/terms'
          mount Identity::V2::Pubkey      => '/pubkey'
          mount Identity::V2::HashDetails => '/hash_details'
          mount Identity::V2::Lookup      => '/lookup'
          mount Identity::V2::Validate::Email  => '/validate/email'
          mount Identity::V2::Validate::Msisdn => '/validate/msisdn'
          mount Identity::V2::ThreePid    => '/3pid'
          mount Identity::V2::StoreInvite => '/store-invite'
          mount Identity::V2::SignEd25519 => '/sign-ed25519'
        end
      end

      # ==================================================================
      # Push Gateway API
      # ==================================================================

      # /_matrix/push
      namespace :push do
        namespace :v1 do
          mount Push::V1::Notify => '/notify'
        end
      end

    end # namespace :_matrix
  end
end
