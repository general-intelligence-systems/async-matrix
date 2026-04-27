# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "yaml"
require "async/matrix"

module Async
	module Matrix
		module ApplicationService
			# Loads and validates an Application Service YAML configuration file.
			#
			# Expected YAML structure:
			#
			#   homeserver:
			#     url: "http://synapse:8008"
			#     domain: "localhost"
			#   appservice:
			#     as_token: "..."
			#     hs_token: "..."
			#     bot_mxid: "@bot:localhost"
			#   server:
			#     bind: "http://0.0.0.0:9292"  # optional
			#
			class Config
				attr_reader :homeserver_url, :domain, :as_token, :hs_token, :bot_mxid, :bind

				def initialize(data)
					hs = data.fetch("homeserver")
					as = data.fetch("appservice")
					sv = data.fetch("server", {})

					@homeserver_url = hs.fetch("url").chomp("/")
					@domain         = hs.fetch("domain")
					@as_token       = as.fetch("as_token")
					@hs_token       = as.fetch("hs_token")
					@bot_mxid       = as.fetch("bot_mxid")
					@bind           = sv.fetch("bind", "http://0.0.0.0:9292")

					validate!
				end

				def self.load(path)
					raise Async::Matrix::NotFoundError.new("M_NOT_FOUND", "Config not found: #{path}") unless File.exist?(path)

					data = YAML.safe_load_file(path, permitted_classes: [Symbol])
					new(data)
				end

				private

				def validate!
					raise Async::Matrix::BadJsonError.new("M_BAD_JSON", "homeserver.url is required")     if @homeserver_url.empty?
					raise Async::Matrix::BadJsonError.new("M_BAD_JSON", "appservice.as_token is required") if @as_token.empty?
					raise Async::Matrix::BadJsonError.new("M_BAD_JSON", "appservice.hs_token is required") if @hs_token.empty?
					raise Async::Matrix::BadJsonError.new("M_BAD_JSON", "appservice.bot_mxid is required") if @bot_mxid.empty?

					if @as_token.include?("CHANGE_ME") || @hs_token.include?("CHANGE_ME")
						raise Async::Matrix::AuthError.new("M_FORBIDDEN", "Replace placeholder tokens in config before starting")
					end
				end
			end
		end
	end
end

test do
	require "tempfile"

	describe "Async::Matrix::ApplicationService::Config" do
		it "parses a valid config hash" do
			config = Async::Matrix::ApplicationService::Config.new({
				"homeserver" => {"url" => "http://localhost:8008", "domain" => "localhost"},
				"appservice" => {"as_token" => "as123", "hs_token" => "hs456", "bot_mxid" => "@bot:localhost"}
			})
			config.homeserver_url.should == "http://localhost:8008"
			config.domain.should == "localhost"
			config.as_token.should == "as123"
			config.hs_token.should == "hs456"
			config.bot_mxid.should == "@bot:localhost"
			config.bind.should == "http://0.0.0.0:9292"
		end

		it "strips trailing slash from homeserver_url" do
			config = Async::Matrix::ApplicationService::Config.new({
				"homeserver" => {"url" => "http://localhost:8008/", "domain" => "localhost"},
				"appservice" => {"as_token" => "as123", "hs_token" => "hs456", "bot_mxid" => "@bot:localhost"}
			})
			config.homeserver_url.should == "http://localhost:8008"
		end

		it "raises BadJsonError for empty as_token" do
			lambda {
				Async::Matrix::ApplicationService::Config.new({
					"homeserver" => {"url" => "http://localhost:8008", "domain" => "localhost"},
					"appservice" => {"as_token" => "", "hs_token" => "hs456", "bot_mxid" => "@bot:localhost"}
				})
			}.should.raise(Async::Matrix::BadJsonError)
		end

		it "raises AuthError for placeholder tokens" do
			lambda {
				Async::Matrix::ApplicationService::Config.new({
					"homeserver" => {"url" => "http://localhost:8008", "domain" => "localhost"},
					"appservice" => {"as_token" => "CHANGE_ME", "hs_token" => "hs456", "bot_mxid" => "@bot:localhost"}
				})
			}.should.raise(Async::Matrix::AuthError)
		end

		it "loads from a YAML file" do
			file = Tempfile.new(["config", ".yml"])
			file.write(<<~YAML)
				homeserver:
				  url: "http://localhost:8008"
				  domain: "localhost"
				appservice:
				  as_token: "as123"
				  hs_token: "hs456"
				  bot_mxid: "@bot:localhost"
			YAML
			file.close

			config = Async::Matrix::ApplicationService::Config.load(file.path)
			config.homeserver_url.should == "http://localhost:8008"
		ensure
			file.unlink
		end

		it "raises NotFoundError for missing file" do
			lambda {
				Async::Matrix::ApplicationService::Config.load("/nonexistent/path.yml")
			}.should.raise(Async::Matrix::NotFoundError)
		end
	end
end
