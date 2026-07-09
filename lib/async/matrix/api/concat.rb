# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    module Api
      # StringBuilder concat handler that renders a method chain into URL path segments.
      #
      # Convention:
      #   - Bare methods become path segments:       .account.whoami -> ["account", "whoami"]
      #   - Methods with args inject the arg as a path segment after the method name:
      #       .rooms("!abc:ex.com") -> ["rooms", "!abc:ex.com"]
      #   - .call("literal") injects a raw path segment:
      #       .("m.room.message") -> ["m.room.message"]
      #
      # The handler returns an array of raw (unencoded) segments.
      # URL-encoding is applied later when constructing the final URL.
      #
      class Concat
        def self.call(buffer)
          new(buffer).segments
        end

        def initialize(buffer)
          @buffer = buffer.respond_to?(:to_a) ? buffer.to_a : buffer
        end

        def segments
          result = []

          @buffer.each do |entry|
            case entry
            when Symbol
              # :slash, :dash -- ignore in URL context
              next
            when Array
              name, args = entry
              next unless name.is_a?(String)

              if args.nil? || args.empty?
                # Bare method -> path segment
                result << name
              else
                # Method with args -> method name as segment, then each arg as segment
                result << name
                args.each do |arg|
                  next if arg.is_a?(Hash) # kwargs are not path segments
                  result << arg.to_s
                end
              end
            end
          end

          result
        end
      end
    end
  end
end

__END__
  require "string_builder"

  describe "Async::Matrix::Api::Concat" do
    it "converts bare methods to path segments" do
      sb = StringBuilder.new
      sb.account.whoami
      segments = Async::Matrix::Api::Concat.call(sb)
      segments.should == %w[account whoami]
    end

    it "converts methods with args to segment + arg" do
      sb = StringBuilder.new
      sb.rooms("!abc:ex.com").ban
      segments = Async::Matrix::Api::Concat.call(sb)
      segments.should == %w[rooms !abc:ex.com ban]
    end

    it "handles methods with multiple args" do
      sb = StringBuilder.new
      sb.rooms("!abc:ex.com").state("m.room.name", "some_key")
      segments = Async::Matrix::Api::Concat.call(sb)
      segments.should == %w[rooms !abc:ex.com state m.room.name some_key]
    end

    it "handles deep paths" do
      sb = StringBuilder.new
      sb.rooms("!abc:ex.com").state("m.room.name", "")
      segments = Async::Matrix::Api::Concat.call(sb)
      segments.should == ["rooms", "!abc:ex.com", "state", "m.room.name", ""]
    end

    it "ignores kwargs in segments" do
      sb = StringBuilder.new
      sb.account.whoami
      segments = Async::Matrix::Api::Concat.call(sb)
      segments.should == %w[account whoami]
    end
  end
