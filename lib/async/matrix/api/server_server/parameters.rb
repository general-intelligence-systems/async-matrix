# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "protocol/url/encoding"

module Async
  module Matrix
    module ServerServer
      # A parameter which is given more than once.
      module Parameters
        class << self
          # One parameter, given once per value.
          #
          # `Protocol::URL::Reference` would write `v[]=one`, which a server does not read.
          #
          # @parameter name [String | Symbol] the parameter's name.
          # @parameter values [Array] the values to give it.
          # @returns [String] the query string, which is empty where there are no values.
          def repeated(name, values)
            Array(values).map do |value|
              "#{name}=#{::Protocol::URL::Encoding.escape(value.to_s)}"
            end.join("&")
          end

          # A query string, from the parameters which are given once and those which are repeated.
          #
          # @parameter repeated [Hash] the parameters to give once per value.
          # @parameter single [Hash] the parameters to give once, whose nil values are left out.
          # @returns [String] the query string, which is empty where there is nothing to say.
          def query(repeated: {}, single: {})
            parts = repeated.map{|name, values| self.repeated(name, values)}

            parts += single.compact.map do |name, value|
              "#{name}=#{::Protocol::URL::Encoding.escape(value.to_s)}"
            end

            parts.reject(&:empty?).join("&")
          end

          # The path with its query appended, where there is one.
          #
          # @parameter path [String] the path to ask for.
          # @parameter query [String] the query string, which may be empty.
          # @returns [String] the path, as the request asks for it.
          def path(path, query)
            if query.empty?
              path
            else
              "#{path}?#{query}"
            end
          end
        end
      end
    end
  end
end
