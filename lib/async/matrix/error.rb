# frozen_string_literal: true

# Released under the Apache License, Version 2.0.
# Copyright, 2026, by General Intelligence Systems.

module Async
  module Matrix
    class Error < StandardError
      attr_reader :errcode, :status

      def initialize(errcode, message, status: nil)
        @errcode = errcode
        @status = status
        super(message)
      end
    end
  end
end

__END__
  describe "Async::Matrix::Error" do
    it "stores errcode and message" do
      err = Async::Matrix::Error.new("M_UNKNOWN", "something broke")
      err.errcode.should == "M_UNKNOWN"
      err.message.should == "something broke"
    end

    it "stores optional status" do
      err = Async::Matrix::Error.new("M_UNKNOWN", "bad", status: 400)
      err.status.should == 400
    end

    it "defaults status to nil" do
      Async::Matrix::Error.new("M_UNKNOWN", "bad").status.should.be.nil
    end

    it "is a StandardError" do
      Async::Matrix::Error.new("M_UNKNOWN", "bad").should.be.kind_of StandardError
    end
  end
