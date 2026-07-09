# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "json"
require "pathname"
require "uri"
require_relative "../../matrix/api/path_tree"

module Async
  module Discord
    module Api
      # Loads the Discord HTTP API OpenAPI spec and builds a PathTree trie
      # of all valid endpoints. Reuses the core Node/insert/match logic from
      # Async::Matrix::Api::PathTree.
      #
      # The Discord spec is a single JSON file (OpenAPI 3.1.0) with the server
      # URL https://discord.com/api/v10, yielding prefix segments ["api", "v10"].
      #
      #   tree = PathTree.load
      #   tree.match(%w[api v10 channels 123 messages], "POST")
      #   # => { valid: true, operation_id: "create_message", methods: ["post"] }
      #
      class PathTree < Async::Matrix::Api::PathTree
        SCHEMA_PATH = Pathname.new(File.expand_path("../../../../data/discord-api-spec/openapi.json", __dir__)).freeze

        def self.load(schema_path: SCHEMA_PATH)
          tree = new
          tree.load_json_schema(schema_path)
          tree
        end

        # Parse the Discord OpenAPI JSON file and insert all paths into the trie.
        def load_json_schema(path)
          doc = JSON.parse(File.read(path))

          base_path = extract_json_base_path(doc)
          paths = doc["paths"]
          return unless paths.is_a?(Hash)

          paths.each do |path_template, methods_hash|
            next unless methods_hash.is_a?(Hash)

            full_path = "#{base_path}#{path_template.strip}"
            segments = full_path.split("/").reject(&:empty?)

            methods_hash.each do |method, operation|
              # Skip path-level parameters (Discord spec puts these alongside methods)
              next if method == "parameters"
              next unless %w[get post put delete patch head].include?(method)
              operation_id = operation.is_a?(Hash) ? operation["operationId"] : nil
              insert(segments, method, operation_id)
            end
          end
        end

        private

          def extract_json_base_path(doc)
            servers = doc["servers"]
            return "" unless servers.is_a?(Array) && servers.first.is_a?(Hash)

            url = servers.first["url"]
            return "" unless url

            URI.parse(url).path
          rescue URI::InvalidURIError
            ""
          end
      end
    end
  end
end

__END__
  describe "Async::Discord::Api::PathTree" do
    it "loads from the Discord OpenAPI spec" do
      tree = Async::Discord::Api::PathTree.load

      # channels/{id}/messages should exist
      result = tree.match(%w[api v10 channels 123456 messages], "POST")
      result[:valid].should == true
      result[:operation_id].should == "create_message"

      # guilds/{id} should exist
      result = tree.match(%w[api v10 guilds 789 channels], "GET")
      result[:valid].should == true

      # users/@me should exist
      result = tree.match(%w[api v10 users @me], "GET")
      result[:valid].should == true
    end

    it "rejects unknown paths" do
      tree = Async::Discord::Api::PathTree.load
      result = tree.match(%w[api v10 totallyFake], "GET")
      result[:valid].should == false
    end

    it "rejects wrong HTTP method" do
      tree = Async::Discord::Api::PathTree.load
      # GET on a POST-only endpoint
      result = tree.match(%w[api v10 channels 123 messages], "DELETE")
      # DELETE is not valid on /channels/{id}/messages (only GET and POST)
      result[:valid].should == false
    end

    it "supports PATCH method (Discord uses it heavily)" do
      tree = Async::Discord::Api::PathTree.load
      # PATCH /channels/{id} should exist
      result = tree.match(%w[api v10 channels 123], "PATCH")
      result[:valid].should == true
    end

    it "inherits from Async::Matrix::Api::PathTree" do
      Async::Discord::Api::PathTree.ancestors.should.include Async::Matrix::Api::PathTree
    end

    it "supports manual insert and match" do
      tree = Async::Discord::Api::PathTree.new
      tree.insert(%w[api v10 test {id} action], "post", "testAction")
      result = tree.match(%w[api v10 test 12345 action], "POST")
      result[:valid].should == true
      result[:operation_id].should == "testAction"
    end
  end
