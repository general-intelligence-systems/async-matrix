# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    # Wraps the content object of a Matrix event, providing typed access to
    # schema-defined properties via method_missing.
    #
    # Common fields like `msgtype`, `body`, and `membership` have dedicated
    # accessors for convenience. Any other field defined in the event's schema
    # (or present in the raw hash) is accessible as a method call:
    #
    #   content.msgtype      # => "m.text"
    #   content.body         # => "hello"
    #   content.membership   # => "join"
    #   content.avatar_url   # => "mxc://example.org/abc"
    #   content["custom"]    # => direct hash access for non-standard fields
    #
    class Content
      attr_reader :msgtype, :body, :membership

      def initialize(data)
        @data       = data
        @msgtype    = data["msgtype"]
        @body       = data["body"]
        @membership = data["membership"]
      end

      def to_h = @data
      def to_s = @body.to_s
      def to_str = to_s

      # Direct hash access for any content field.
      def [](key) = @data[key.to_s]

      # Dynamic access to any content field present in the raw data.
      def method_missing(name, *args)
        key = name.to_s

        if @data.key?(key)
          @data[key]
        else
          nil
        end
      end

      def respond_to_missing?(name, include_private = false)
        @data.key?(name.to_s) || super
      end
    end
  end
end

__END__
  describe "Async::Matrix::Content" do
    it "parses msgtype, body, and membership" do
      content = Async::Matrix::Content.new({
        "msgtype" => "m.text",
        "body" => "hello",
        "membership" => "join"
      })
      content.msgtype.should == "m.text"
      content.body.should == "hello"
      content.membership.should == "join"
    end

    it "handles missing fields gracefully" do
      content = Async::Matrix::Content.new({})
      content.msgtype.should.be.nil
      content.body.should.be.nil
      content.membership.should.be.nil
    end

    it "provides hash access via []" do
      content = Async::Matrix::Content.new({"custom_field" => "value"})
      content["custom_field"].should == "value"
    end

    it "provides dynamic access via method_missing" do
      content = Async::Matrix::Content.new({
        "avatar_url" => "mxc://example.org/abc",
        "displayname" => "Alice"
      })
      content.avatar_url.should == "mxc://example.org/abc"
      content.displayname.should == "Alice"
    end

    it "returns nil for unknown fields via method_missing" do
      content = Async::Matrix::Content.new({})
      content.nonexistent.should.be.nil
    end

    it "returns the raw hash via to_h" do
      data = {"msgtype" => "m.text", "body" => "hi"}
      content = Async::Matrix::Content.new(data)
      content.to_h.should == data
    end

    it "responds to keys present in the data" do
      content = Async::Matrix::Content.new({"avatar_url" => "mxc://x/y"})
      content.respond_to?(:avatar_url).should == true
      content.respond_to?(:nonexistent).should == false
    end
  end
