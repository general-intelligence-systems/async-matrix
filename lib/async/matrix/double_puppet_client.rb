# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
  module Matrix
    # A Client subclass that authenticates with a user's double puppet token
    # instead of the appservice's as_token.
    #
    # This allows the bridge to send events as the real Matrix user rather
    # than as the appservice bot or a ghost user.
    #
    #   puppet = DoublePuppetClient.new(config, double_puppet_token: "syt_...")
    #   puppet.send_text("!room:example.com", "sent as the real user")
    #   puppet.whoami  # => {"user_id" => "@alice:example.com"}
    #
    class DoublePuppetClient < Client
      def initialize(config, double_puppet_token:, **kwargs)
        super(config, **kwargs)
        @headers[0] = ["authorization", "Bearer #{double_puppet_token}"]
      end
    end
  end
end

test do
  describe "Async::Matrix::DoublePuppetClient" do
    def make_config
      Async::Matrix::ApplicationService::Config.new({
        "homeserver" => { "address" => "http://localhost:8008", "domain" => "localhost" },
        "appservice" => { "as_token" => "as_token_value", "hs_token" => "hs_secret", "bot" => { "username" => "bot" } }
      })
    end

    it "uses the double_puppet_token for authorization" do
      puppet = Async::Matrix::DoublePuppetClient.new(make_config, double_puppet_token: "syt_puppet_token")
      auth_header = puppet.instance_variable_get(:@headers).find { |k, _| k == "authorization" }
      auth_header[1].should == "Bearer syt_puppet_token"
    end

    it "does not use the as_token from config" do
      puppet = Async::Matrix::DoublePuppetClient.new(make_config, double_puppet_token: "syt_puppet_token")
      auth_header = puppet.instance_variable_get(:@headers).find { |k, _| k == "authorization" }
      auth_header[1].should.not.include "as_token_value"
    end

    it "inherits retry defaults from Client" do
      puppet = Async::Matrix::DoublePuppetClient.new(make_config, double_puppet_token: "syt_puppet_token")
      puppet.config.appservice.as_token.should == "as_token_value"
    end

    it "accepts custom retry configuration" do
      puppet = Async::Matrix::DoublePuppetClient.new(
        make_config,
        double_puppet_token: "syt_puppet_token",
        max_retries: 5,
        retry_base_delay: 1.0,
        max_retry_delay: 60
      )
      auth_header = puppet.instance_variable_get(:@headers).find { |k, _| k == "authorization" }
      auth_header[1].should == "Bearer syt_puppet_token"
    end

    it "responds to all Client methods" do
      puppet = Async::Matrix::DoublePuppetClient.new(make_config, double_puppet_token: "syt_puppet_token")
      puppet.should.respond_to :send_text
      puppet.should.respond_to :send_html
      puppet.should.respond_to :send_notice
      puppet.should.respond_to :join_room
      puppet.should.respond_to :leave_room
      puppet.should.respond_to :whoami
      puppet.should.respond_to :api
    end

    it "is a subclass of Client" do
      puppet = Async::Matrix::DoublePuppetClient.new(make_config, double_puppet_token: "syt_puppet_token")
      puppet.should.be.kind_of Async::Matrix::Client
    end
  end
end
