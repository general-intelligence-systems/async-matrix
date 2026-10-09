# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require_relative "client"

module Async
  module Matrix
    # A Client that acts AS one of the appservice's users, on one of that user's
    # devices.
    #
    #   client = AppServiceClient.new(config, user_id: "@ada:example.org", device_id: "ABCDEFGHIJ")
    #   client.upload_keys(device_keys: ...)   # uploaded for Ada's device, not the bot's
    #
    # This is double puppeting, and it is the officially intended mechanism
    # rather than a trick. Identity assertion -- `?user_id=` -- has been in the
    # application service spec for years; [MSC4326] added `?device_id=` beside
    # it and is MERGED, so the plain parameter names below are stable spec, not
    # the unstable `org.matrix.msc3202.device_id` an older implementation would
    # have sent.
    #
    # WHY NOT A TOKEN. Bridges used to get a per-user access token by calling
    # /login with `m.login.application_service` ([MSC2778]), and that route is
    # gone on a homeserver fronted by OAuth2 -- it answers
    # M_APPSERVICE_LOGIN_UNSUPPORTED. [MSC4190], which is also merged, replaced
    # it: an appservice creates devices directly (`PUT /devices/{deviceId}`) and
    # then acts as them with these two parameters. No token is ever issued, so
    # none can expire or need refreshing.
    #
    # IT STILL WORKS BEHIND MAS. Synapse checks an as_token against its own
    # appservice registry before it introspects anything at the authentication
    # service, so masquerading is unaffected by next-generation auth.
    #
    # THE USER MUST BE IN THE REGISTRATION'S NAMESPACE. The homeserver refuses
    # otherwise -- which is why a double-puppet registration claims a wide user
    # namespace non-exclusively rather than naming individuals.
    #
    # [MSC4326]: https://github.com/matrix-org/matrix-spec-proposals/pull/4326
    # [MSC4190]: https://github.com/matrix-org/matrix-spec-proposals/pull/4190
    # [MSC2778]: https://github.com/matrix-org/matrix-spec-proposals/pull/2778
    class AppServiceClient < Client
      # @parameter user_id [String] the user to act as. Must match the
      #   registration's user namespace.
      # @parameter device_id [String] the device to act as.
      #
      #   WITHOUT IT THE REQUEST HAS NO DEVICE, and an appservice request with
      #   no device cannot upload one-time keys, claim keys or send to-device
      #   messages -- every call encryption is made of. It is optional only
      #   because the device has to be CREATED before it can be acted as, and
      #   that one call is made without it.
      def initialize(config, user_id:, device_id: nil, **options)
        super(config, **options)

        @user_id = user_id
        @device_id = device_id
      end

      attr_reader :user_id, :device_id

      # NAMED ON EVERY REQUEST, not only the ones that obviously need it. An
      # appservice request that omits them is not an error: it silently acts as
      # the registration's sender_localpart, with no device, which is far worse
      # than a failure because it succeeds.
      def default_query
        {user_id: @user_id}.tap do |query|
          if @device_id
            query[:device_id] = @device_id
          end
        end
      end

      # A sibling client for another user or device, sharing this one's config
      # and retry policy.
      #
      # One appservice commonly acts for many users, and the alternative --
      # mutating user_id on a single client -- races itself the moment two
      # fibers use it, which is exactly what an async bridge does.
      def as(user_id:, device_id: nil)
        self.class.new(@config, user_id: user_id, device_id: device_id)
      end

      # The same user, now on a device: what you call once the device exists.
      def with_device(device_id)
        as(user_id: @user_id, device_id: device_id)
      end
    end
  end
end

__END__
  describe "Async::Matrix::AppServiceClient" do
    def config
      Async::Matrix::Config.new({
        "homeserver" => {"address" => "http://synapse:8008", "domain" => "example.org"},
        "appservice" => {"as_token" => "as", "hs_token" => "hs", "bot" => {"username" => "bot"}},
      })
    end

    def recording_client(user_id: "@ada:example.org", device_id: "ABCDEFGHIJ")
      Async::Matrix::Api.reset!

      client = Async::Matrix::AppServiceClient.new(config, user_id: user_id, device_id: device_id)
      calls = []
      client.define_singleton_method(:calls) { calls }
      client.define_singleton_method(:internet) do
        internet = Object.new
        internet.define_singleton_method(:call) do |method, url, _headers, _body|
          calls << [method, url]

          # Shaped like what Client#read_limited consumes: a body that yields
          # chunks and reports its own length.
          body = Object.new
          body.define_singleton_method(:length) { 2 }
          body.define_singleton_method(:each) { |&block| block.call("{}") }
          body.define_singleton_method(:close) { nil }

          response = Object.new
          response.define_singleton_method(:status) { 200 }
          response.define_singleton_method(:body) { body }
          response.define_singleton_method(:close) { nil }
          response
        end
        internet
      end
      client
    end

    def last_url(client) = client.calls.last[1]

    it "asserts the user and device on every request" do
      client = recording_client
      client.whoami

      last_url(client).should ==
        "http://synapse:8008/_matrix/client/v3/account/whoami" \
        "?user_id=%40ada%3Aexample.org&device_id=ABCDEFGHIJ"
    end

    # Not only on the calls that obviously need it: an appservice request that
    # omits them silently acts as the sender_localpart, with no device.
    it "asserts them through the api chain too" do
      client = recording_client
      client.joined_members(room_id: "!ops:example.org")

      last_url(client).should.be.include? "user_id=%40ada%3Aexample.org"
      last_url(client).should.be.include? "device_id=ABCDEFGHIJ"
    end

    # The chain appends its own query first, so this is the case that catches a
    # naive "?" concatenation.
    it "appends to a path that already carries a query" do
      client = recording_client
      client.messages(room_id: "!ops:example.org", limit: 10)

      last_url(client).should.be.include? "?dir=b&limit=10&"
      last_url(client).should.be.include? "user_id=%40ada%3Aexample.org"
      last_url(client).count("?").should == 1
    end

    # The device has to be created before it can be acted as, and that one call
    # is made without a device.
    it "omits the device when it has none" do
      client = recording_client(device_id: nil)
      client.whoami

      last_url(client).should.be.include? "user_id=%40ada%3Aexample.org"
      last_url(client).should.not.be.include? "device_id"
    end

    # Overwriting it would mean acting as somebody other than the caller asked
    # for, which is worse than a failure.
    it "lets a caller's own parameter win" do
      client = recording_client
      client.get("/_matrix/client/v3/account/whoami?user_id=%40bob%3Aexample.org")

      last_url(client).should.be.include? "user_id=%40bob%3Aexample.org"
      last_url(client).scan("user_id=").length.should == 1
    end

    it "encodes the punctuation in a user id" do
      client = recording_client(user_id: "@ada:example.org")
      client.whoami

      last_url(client).should.be.include? "%40ada%3Aexample.org"
    end

    # One appservice acts for many users; mutating a shared client would race
    # itself the moment two fibers used it.
    it "makes a sibling client for another user" do
      client = recording_client
      other = client.as(user_id: "@bob:example.org", device_id: "OTHERDEV")

      other.user_id.should == "@bob:example.org"
      other.device_id.should == "OTHERDEV"
      client.user_id.should == "@ada:example.org"
      other.config.should.be == client.config
    end

    it "makes a client for the same user on a device" do
      client = recording_client(device_id: nil)
      with_device = client.with_device("NEWDEVICE")

      with_device.user_id.should == "@ada:example.org"
      with_device.device_id.should == "NEWDEVICE"
    end

    # An ordinary client asserts nothing: a user's own token already says who
    # the request is for.
    it "is the only client that asserts anything" do
      Async::Matrix::Client.new(config).default_query.should == {}
    end
  end
