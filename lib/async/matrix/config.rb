# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "forwardable"
require "yaml"
require "pathname"
require_relative "config/vivify"

module Async
  module Matrix
    # Dot-notation access to a Matrix service's YAML configuration.
    #
    # {Client} only reads two fields — `homeserver.address` and
    # `appservice.as_token` — so this class validates nothing: it vivifies
    # whatever hash (or YAML file) it is handed and exposes every nested field
    # as a method call.
    #
    #   config = Config.load("config/appservice.yml")
    #   config.homeserver.address      # => "http://synapse:8008"
    #   config.appservice.as_token     # => "secret..."
    #   config.appservice.bot.username # => "bot"
    #   config.bot_mxid                # => "@bot:localhost"
    #
    # A subclass layers validation on by overriding {.validate!}; that is how
    # async-matrix-bridge's Config applies the mautrix bridgev2 JSON Schema
    # suite without reimplementing any of the loading below.
    class Config
      extend Forwardable

      # Delegate every top-level config section to the vivified data hash. An
      # explicit list, not a method_missing forward: a typo'd section should
      # raise NoMethodError rather than autovivify into an empty hash.
      def_delegators :@data,
        :network,
        :bridge,
        :database,
        :homeserver,
        :appservice,
        :matrix,
        :analytics,
        :provisioning,
        :public_media,
        :direct_media,
        :backfill,
        :double_puppet,
        :encryption,
        :logging,
        :management_room_texts,
        :env_config_prefix

      def initialize(data)
        self.class.validate!(data)
        @data = Vivify.deep_vivify(data)
      end

      # Load a YAML config file from disk.
      def self.load(path)
        unless File.exist?(path)
          raise Async::Matrix::NotFoundError.new(
            "M_NOT_FOUND",
            "Config not found: #{path}",
          )
        end

        data = YAML.safe_load_file(path, permitted_classes: [Symbol])
        new(data)
      end

      # Validation hook, called with the raw (string-keyed) hash before it is
      # vivified. A no-op here; subclasses override it to raise on bad input,
      # and may mutate `data` to insert defaults.
      def self.validate!(data)
        nil
      end

      # Convenience: derive the bot's full Matrix ID from
      # appservice.bot.username + homeserver.domain.
      def bot_mxid
        "@#{appservice.bot.username}:#{homeserver.domain}"
      end
    end
  end
end

__END__
  require "tempfile"

  describe "Async::Matrix::Config" do
    def minimal_data
      {
        "homeserver" => {
          "address" => "http://localhost:8008",
          "domain"  => "localhost",
        },
        "appservice" => {
          "as_token" => "as_secret_token_value",
          "hs_token" => "hs_secret_token_value",
          "bot"      => {"username" => "bot"},
        },
      }
    end

    it "exposes top-level sections" do
      config = Async::Matrix::Config.new(minimal_data)
      config.homeserver.address.should == "http://localhost:8008"
      config.homeserver.domain.should == "localhost"
      config.appservice.as_token.should == "as_secret_token_value"
      config.appservice.hs_token.should == "hs_secret_token_value"
      config.appservice.bot.username.should == "bot"
    end

    it "derives bot_mxid from appservice.bot.username and homeserver.domain" do
      Async::Matrix::Config.new(minimal_data).bot_mxid.should == "@bot:localhost"
    end

    it "provides dot-notation access to deeply nested fields" do
      data = minimal_data.merge(
        "encryption" => {
          "allow" => true,
          "rotation" => {"messages" => 200},
        },
      )
      config = Async::Matrix::Config.new(data)
      config.encryption.allow.should == true
      config.encryption.rotation.messages.should == 200
    end

    it "autovivifies missing optional sections as empty hashes" do
      config = Async::Matrix::Config.new(minimal_data)
      config.analytics.should.be.kind_of Hash
      config.analytics.should.be.empty?
    end

    it "raises NoMethodError for sections it does not delegate" do
      config = Async::Matrix::Config.new(minimal_data)
      lambda { config.bogus }.should.raise(NoMethodError)
    end

    it "validates nothing by default" do
      lambda { Async::Matrix::Config.new({}) }.should.not.raise
    end

    it "loads from a YAML file" do
      file = Tempfile.new(["config", ".yml"])
      file.write(<<~YAML)
        homeserver:
          address: "http://localhost:8008"
          domain: "localhost"
        appservice:
          as_token: "as123_secret"
          hs_token: "hs456_secret"
          bot:
            username: "testbot"
      YAML
      file.close

      config = Async::Matrix::Config.load(file.path)
      config.homeserver.address.should == "http://localhost:8008"
      config.bot_mxid.should == "@testbot:localhost"
    ensure
      file.unlink
    end

    it "raises NotFoundError for a missing file" do
      lambda {
        Async::Matrix::Config.load("/nonexistent/path.yml")
      }.should.raise(Async::Matrix::NotFoundError)
    end

    it "runs the validate! hook a subclass overrides" do
      strict = Class.new(Async::Matrix::Config) do
        def self.validate!(data)
          unless data.key?("homeserver")
            raise Async::Matrix::BadJsonError.new("M_BAD_JSON", "no homeserver")
          end
        end
      end

      lambda { strict.new({}) }.should.raise(Async::Matrix::BadJsonError)
      strict.new(minimal_data).homeserver.domain.should == "localhost"
    end
  end
