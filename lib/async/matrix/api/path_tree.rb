# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"
require "yaml"
require "pathname"

module Async
  module Matrix
    module Api
      # A trie of valid Matrix API paths, built from OpenAPI 3.1.0 YAML schemas.
      #
      # Each leaf node stores the set of HTTP methods valid at that path.
      # Template segments like {roomId} become wildcard nodes that match any value.
      #
      # Example:
      #   tree = PathTree.load
      #   tree.match(["_matrix", "client", "v3", "rooms", "!abc:ex.com", "ban"], "POST")
      #   # => { valid: true, operation_id: "ban", methods: ["post"] }
      #
      class PathTree
        SCHEMA_DIR = Pathname.new(File.expand_path("../../../../data/matrix-spec/api/client-server", __dir__))

        Node = Struct.new(:children, :wildcard, :methods, :operation_ids, keyword_init: true) do
          def initialize(**)
            super
            self.children ||= {}
            self.methods ||= []
            self.operation_ids ||= {}
          end
        end

        attr_reader :root

        def initialize
          @root = Node.new
        end

        # Load all OpenAPI schemas from data/ and build the tree.
        def self.load(schema_dir: SCHEMA_DIR)
          tree = new
          Pathname.glob(schema_dir / "*.yaml").each do |path|
            tree.load_schema(path)
          end
          tree
        end

        # Parse a single OpenAPI YAML file and insert its paths into the tree.
        def load_schema(path)
          doc = YAML.safe_load(File.read(path), permitted_classes: [Symbol], aliases: true)
          return unless doc.is_a?(Hash)

          base_path = extract_base_path(doc)
          paths = doc["paths"]
          return unless paths.is_a?(Hash)

          paths.each do |path_template, methods_hash|
            next unless methods_hash.is_a?(Hash)

            # Build full path: basePath + path_template
            full_path = "#{base_path}#{path_template.strip}"
            segments = full_path.split("/").reject(&:empty?)

            methods_hash.each do |method, operation|
              next unless %w[get post put delete patch head].include?(method)
              operation_id = operation.is_a?(Hash) ? operation["operationId"] : nil
              insert(segments, method, operation_id)
            end
          end
        end

        # Insert a path (as array of segments) with an HTTP method into the trie.
        def insert(segments, method, operation_id = nil)
          node = @root
          segments.each do |segment|
            if segment.start_with?("{") && segment.end_with?("}")
              # Wildcard segment — matches any value
              node.wildcard ||= Node.new
              node = node.wildcard
            else
              node.children[segment] ||= Node.new
              node = node.children[segment]
            end
          end
          node.methods << method.downcase unless node.methods.include?(method.downcase)
          node.operation_ids[method.downcase] = operation_id if operation_id
        end

        # Match a concrete path (array of segments) against the trie.
        # Returns a result hash.
        def match(segments, method = nil)
          node = @root
          segments.each do |segment|
            if node.children.key?(segment)
              node = node.children[segment]
            elsif node.wildcard
              node = node.wildcard
            else
              return {valid: false, methods: [], operation_id: nil}
            end
          end

          if method
            method_down = method.downcase
            valid = node.methods.include?(method_down)
            {valid: valid, methods: node.methods, operation_id: node.operation_ids[method_down]}
          else
            {valid: node.methods.any?, methods: node.methods, operation_id: nil}
          end
        end

        private

        def extract_base_path(doc)
          servers = doc["servers"]
          return "" unless servers.is_a?(Array) && servers.first.is_a?(Hash)

          server = servers.first
          variables = server["variables"] || {}
          base_path_var = variables["basePath"]
          return "" unless base_path_var.is_a?(Hash)

          base_path_var["default"] || ""
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::Api::PathTree" do
    def make_tree
      tree = Async::Matrix::Api::PathTree.new
      # Simulate a few endpoints manually
      tree.insert(%w[_matrix client v3 account whoami], "get", "getAccountWhoami")
      tree.insert(%w[_matrix client v3 createRoom], "post", "createRoom")
      tree.insert(%w[_matrix client v3 rooms {roomId} ban], "post", "ban")
      tree.insert(%w[_matrix client v3 rooms {roomId} unban], "post", "unban")
      tree.insert(%w[_matrix client v3 rooms {roomId} state {eventType} {stateKey}], "get", "getRoomStateWithKey")
      tree.insert(%w[_matrix client v3 rooms {roomId} state {eventType} {stateKey}], "put", "setRoomStateWithKey")
      tree.insert(%w[_matrix client v3 rooms {roomId} messages], "get", "getRoomMessages")
      tree.insert(%w[_matrix client v3 profile {userId} displayname], "get", "getDisplayName")
      tree.insert(%w[_matrix client v3 profile {userId} displayname], "put", "setDisplayName")
      tree
    end

    it "matches a simple path" do
      tree = make_tree
      result = tree.match(%w[_matrix client v3 account whoami], "GET")
      result[:valid].should == true
      result[:operation_id].should == "getAccountWhoami"
    end

    it "rejects unknown paths" do
      tree = make_tree
      result = tree.match(%w[_matrix client v3 account foobar], "GET")
      result[:valid].should == false
    end

    it "matches wildcard segments" do
      tree = make_tree
      result = tree.match(%w[_matrix client v3 rooms !abc:ex.com ban], "POST")
      result[:valid].should == true
      result[:operation_id].should == "ban"
    end

    it "matches deep wildcard paths" do
      tree = make_tree
      result = tree.match(%w[_matrix client v3 rooms !abc:ex.com state m.room.name some_key], "GET")
      result[:valid].should == true
      result[:operation_id].should == "getRoomStateWithKey"
    end

    it "rejects wrong HTTP method" do
      tree = make_tree
      result = tree.match(%w[_matrix client v3 account whoami], "POST")
      result[:valid].should == false
    end

    it "reports available methods" do
      tree = make_tree
      result = tree.match(%w[_matrix client v3 profile @user:ex.com displayname])
      result[:valid].should == true
      result[:methods].should.include "get"
      result[:methods].should.include "put"
    end

    it "loads from real schema files" do
      skip "schemas not present" unless Async::Matrix::Api::PathTree::SCHEMA_DIR.exist?
      tree = Async::Matrix::Api::PathTree.load
      # createRoom should exist
      result = tree.match(%w[_matrix client v3 createRoom], "POST")
      result[:valid].should == true
      # rooms/{id}/ban should exist
      result = tree.match(%w[_matrix client v3 rooms !test:ex.com ban], "POST")
      result[:valid].should == true
      # sync should exist
      result = tree.match(%w[_matrix client v3 sync], "GET")
      result[:valid].should == true
      # nonsense should not
      result = tree.match(%w[_matrix client v3 totallyFake], "GET")
      result[:valid].should == false
    end
  end
end
