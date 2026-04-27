# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

require "bundler/setup"
require "async/matrix"

module Async
  module Matrix
    module ApplicationService
      class ErrorResponse
        attr_reader :errcode, :error

        def initialize(data)
          @errcode = data["errcode"]
          @error   = data["error"]
        end
      end
    end
  end
end

test do
  describe "Async::Matrix::ApplicationService::ErrorResponse" do
    it "parses errcode and error" do
      resp = Async::Matrix::ApplicationService::ErrorResponse.new({
        "errcode" => "M_FORBIDDEN",
        "error" => "Access denied"
      })
      resp.errcode.should == "M_FORBIDDEN"
      resp.error.should == "Access denied"
    end

    it "handles missing fields" do
      resp = Async::Matrix::ApplicationService::ErrorResponse.new({})
      resp.errcode.should.be.nil
      resp.error.should.be.nil
    end
  end
end
